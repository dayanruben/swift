import hashlib
import os
import re
import shlex
import subprocess
import pathlib

"""
This file provides the `generate_test_lit_plugin` function, which is invoked on failed RUN lines when lit is executed with --update-tests.
It checks whether the test file contains a GENERATED-BY: line, and if so executes that line (after performing lit substitutions) and updates the file with the output.
All lines before GENERATED-BY: are kept as is.
If the GENERATED-BY is in a `split-file` slice it updates the corresponding slice in the source file.
"""

_GENERATED_BY_RE = re.compile(r"^//\s*GENERATED-BY:\s*(.*)")
_GENERATED_HASH_RE = re.compile(r"^//\s*GENERATED-HASH:\s*(.*)")


class SplitFileTarget:
    def __init__(self, slice_start_idx, test_path, lines, name):
        self.slice_start_idx = slice_start_idx
        self.test_path = test_path
        self.lines = lines
        self.name = name

    def copyFrom(self, source):
        lines_before = self.lines[: self.slice_start_idx + 1]
        self.lines = self.lines[self.slice_start_idx + 1 :]
        slice_end_idx = None
        for i, l in enumerate(self.lines):
            if SplitFileTarget._get_split_line_path(l) != None:
                slice_end_idx = i
                break
        if slice_end_idx is not None:
            lines_after = self.lines[slice_end_idx:]
        else:
            lines_after = []
        with open(source, "r") as f:
            new_lines = lines_before + f.readlines() + lines_after
        with open(self.test_path, "w") as f:
            for l in new_lines:
                f.write(l)

    def __str__(self):
        return f"slice {self.name} in {self.test_path}"

    @staticmethod
    def get_target_dir(commands, test_path):
        # posix=True breaks Windows paths because \ is treated as an escaping character
        for cmd in commands:
            split = shlex.split(cmd, posix=False)
            if "split-file" not in split:
                continue
            start_idx = split.index("split-file")
            split = split[start_idx:]
            if len(split) < 3:
                continue
            p = unquote(split[1].strip())
            if not test_path.samefile(p):
                continue
            return unquote(split[2].strip())
        return None

    @staticmethod
    def create(path, commands, test_path, target_dir):
        path = pathlib.Path(path)
        with open(test_path, "r") as f:
            lines = f.readlines()
        for i, l in enumerate(lines):
            p = SplitFileTarget._get_split_line_path(l)
            if p and path.samefile(os.path.join(target_dir, p)):
                idx = i
                break
        else:
            return None
        return SplitFileTarget(idx, test_path, lines, p)

    @staticmethod
    def _get_split_line_path(l):
        if len(l) < 6:
            return None
        if l.startswith("//"):
            l = l[2:]
        else:
            l = l[1:]
        if l.startswith("--- "):
            l = l[4:]
        else:
            return None
        return l.rstrip()


def unquote(s):
    if len(s) > 1 and s[0] == s[-1] and (s[0] == '"' or s[0] == "'"):
        return s[1:-1]
    return s


def propagate_split_files(test_path, updated_files, commands):
    test_path = pathlib.Path(test_path)
    split_target_dir = SplitFileTarget.get_target_dir(commands, test_path)
    if not split_target_dir:
        return updated_files

    new = []
    for file in updated_files:
        target = SplitFileTarget.create(
            file, commands, test_path, split_target_dir
        )
        if target:
            target.copyFrom(file)
            new.append(str(target))
        else:
            new.append(file)
    return new


def _run_and_update(test_path, cmd):
    """
    Run `cmd`, use its stdout to replace the GENERATED-BY section content in
    `test_path`. A GENERATED-HASH comment is inserted after the GENERATED-BY
    line containing a SHA-256 hash of the output. If the file already contains
    a GENERATED-HASH and the hash matches, the file is not rewritten.

    Returns (error_string, False) on failure.
    Returns (None, False) if the hash is unchanged and the file was not updated.
    Returns (None, True) if the file was updated.
    """
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if proc.returncode != 0:
        return (f"GENERATED-BY command failed:\n{proc.stderr}", False)

    output = proc.stdout

    with open(test_path, "r") as f:
        lines = f.readlines()

    generated_by_idx = None
    for i, line in enumerate(lines):
        if _GENERATED_BY_RE.match(line.strip()):
            generated_by_idx = i
            break

    assert (
        generated_by_idx is not None
    ), f"GENERATED-BY not found in {test_path}"

    new_hash = hashlib.sha256(output.encode()).hexdigest()

    # Check for an existing GENERATED-HASH line immediately after GENERATED-BY.
    content_start = generated_by_idx + 1
    old_hash = None
    if content_start < len(lines):
        m = _GENERATED_HASH_RE.match(lines[content_start].strip())
        if m:
            old_hash = m.group(1).strip()
            content_start += 1

    if old_hash == new_hash:
        return (None, False)

    slice_end = None
    for i, line in enumerate(lines[content_start:], start=content_start):
        if SplitFileTarget._get_split_line_path(line) is not None:
            slice_end = i
            break

    output_lines = output.splitlines(keepends=True)
    if output_lines and not output_lines[-1].endswith("\n"):
        output_lines[-1] += "\n"

    hash_line = f"// GENERATED-HASH: {new_hash}\n"
    lines_after = lines[slice_end:] if slice_end is not None else []

    with open(test_path, "w") as f:
        f.writelines(
            lines[: generated_by_idx + 1] + [hash_line] + output_lines + lines_after
        )

    return (None, True)


def update_generated_test(test_path, substitutions):
    """
    Standalone entry point (used by update-generated-tests.py).
    Find the GENERATED-BY directive in test_path, apply `substitutions` (a
    sequence of (pattern, replacement) pairs as accepted by
    lit.TestRunner.applySubstitutions), run the resulting command, and update
    the file with the output.

    Returns (None, None) if no GENERATED-BY was found, or if the output did not
    change since last generation.
    Returns (error_string, None) on failure.
    Returns (None, message_string) on success.
    """
    from lit.TestRunner import applySubstitutions

    with open(test_path, "r") as f:
        lines = f.readlines()

    for line in lines:
        m = _GENERATED_BY_RE.match(line.strip())
        if m:
            [cmd] = applySubstitutions([m.group(1).strip()], substitutions)
            (err, changed) = _run_and_update(test_path, cmd)
            if err:
                return (err, None)
            if changed:
                return (None, f"updated file: {test_path}")

    return (None, None)


def generate_test_lit_plugin(result, test, commands):
    from lit.TestRunner import getTempPaths, getDefaultSubstitutions

    tmpDir, tmpBase = getTempPaths(test)
    substitutions = getDefaultSubstitutions(test, tmpDir, tmpBase)
    (err, msg) = update_generated_test(test.getFilePath(), substitutions)
    return err or msg
