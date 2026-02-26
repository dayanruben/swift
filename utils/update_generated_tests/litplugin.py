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
    `test_path`. Everything before and including the GENERATED-BY line is
    preserved; content after it up to the next split-file section header (or
    EOF) is replaced with the command output.

    Returns an error string on failure, or None on success.
    """
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if proc.returncode != 0:
        return f"GENERATED-BY command failed:\n{proc.stderr}"

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

    slice_end = None
    for i, line in enumerate(
        lines[generated_by_idx + 1 :], start=generated_by_idx + 1
    ):
        if SplitFileTarget._get_split_line_path(line) is not None:
            slice_end = i
            break

    output_lines = output.splitlines(keepends=True)
    if output_lines and not output_lines[-1].endswith("\n"):
        output_lines[-1] += "\n"

    lines_after = lines[slice_end:] if slice_end is not None else []

    with open(test_path, "w") as f:
        f.writelines(lines[: generated_by_idx + 1] + output_lines + lines_after)

    return None


def update_generated_test(test_path, substitutions):
    """
    Standalone entry point (used by update-generated-tests.py).
    Find the GENERATED-BY directive in test_path, apply `substitutions` (a
    sequence of (pattern, replacement) pairs as accepted by
    lit.TestRunner.applySubstitutions), run the resulting command, and update
    the file with the output.

    Returns (None, None) if no GENERATED-BY was found.
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
            err = _run_and_update(test_path, cmd)
            if err:
                return (err, None)
            return (None, f"updated file: {test_path}")

    return (None, None)


def generate_test_lit_plugin(result, test, commands):
    from lit.TestRunner import getTempPaths, getDefaultSubstitutions

    tmpDir, tmpBase = getTempPaths(test)
    substitutions = getDefaultSubstitutions(test, tmpDir, tmpBase)
    (err, msg) = update_generated_test(test.getFilePath(), substitutions)
    return err or msg
