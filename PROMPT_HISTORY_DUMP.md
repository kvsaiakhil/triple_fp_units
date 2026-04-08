# Prompt History Dump

This file is a reconstructed prompt log for the project session that produced the standalone floating-point unit work in this repo.

It is intended as a design and workflow trace: what was asked, in what order, and how the scope evolved from BOOM/FMA exploration into a standalone custom-FP subproject.

Notes:

- this is reconstructed from the conversation thread, not copied from a separate prompt-export file
- prompts are listed in chronological order
- wording is preserved as closely as possible, with only light normalization where needed for readability

## Chronological Prompt History

### 1. Initial BOOM/RTL exploration

```text
Go through the rtl generated for boomv3 processor using chipyard thorougly
```

### 2. Narrowing focus to the FMA unit

```text
My focus is currently FMA unit, can you create a document with all the details, architecture, hierarchy, filenames for this unit only
```

### 3. Feasibility of standalone triple-op units

```text
Good job, now i have a project in mind, create a new folder and let do the following things:

1. using already existing modules create triple floating point multiply unit - single prec and duoble prec floating point unit. i.e., a*b*c
2. using already existing modules create triple floating point add unit - single prec and duoble prec floating point unit. i.e., a+b+c

First before implementing tell me if this is feasible
```

### 4. Constraint clarification for standalone implementation

```text
Yes i want to only implement standalone triple product and trip add units.
Also, I dont want to chain two fma units, i want to use submodules instantiated inside fma units to build these units from scratch, and i want to maintain the pipeline delays equal to fma unit

what do you think, come up with a plan
```

### 5. End-to-end implementation request

```text
Sure, please go ahead. First build a detailed spec, then validate your spec, then implement rtl, testcases, validate and verify the implementations or provide me testbenches to verify them on offline tools.

Spawn agents as necessary. Complete the implementation and remeber the constraints i have set - the units should match the pipeline stages of orignal fma unit
```

### 6. Local HDL environment and real verification

```text
Can you create a hdl environment, install hdl tools and perform verification?
```

### 7. Increase verification depth with Berkeley HardFloat

```text
Awesome, clone this repository from hardfloat

https://github.com/ucb-bar/berkeley-hardfloat

Use the tests inside this repository to increase coverage, increase no of tests, create tests, and perform deeper verification
```

### 8. Fix remaining triple-multiply issues

```text
Please do

 If you want, I can take the next pass on TripleMulRecFNToRaw.sv and drive those failing cases to ground.
```

### 9. Consider broader verification infrastructure

```text
Now, should we build a uvm infrastructure around these newly implemneted to verify even deeper and broader?
```

### 10. Build a UVM-lite environment

```text
Create a new folder and do this

Best next move:

build a “UVM-lite” environment first around the four top modules in triple_fp_units
use the existing Python/TestFloat flow as the reference model input source
add functional coverage for operand classes, rounding modes, zero/inf/NaN combinations, overflow/underflow, and sign patterns
If you want, I can create that verification architecture next and scaffold the folders/files for a reusable UVM-style environment.

After this, lets us finalize the project
```

### 11. Add Python reference/debug models

```text
Can you create another folder

in the new folder do the following:
1. create a python reference or model for each of our new units
2. add print or debug or log statements after each pipestage or any intermediate vlues coming from each substage in our units
3. this is for my understanding about the format, breakdown and a functional model for my reference

Basically a python equivalent model for each unit we implemented
```

### 12. Project completeness check

```text
This is awesome, do you think the project is somewhat complete
```

### 13. Add a top-level summary document

```text
add a top-level project summary doc that points to RTL, verification, and Python reference folders in one place
```

### 14. Publish to Git

```text
Now, i would like you to push to my git the triple_fp_units directory
```

### 15. Provide the remote repository

```text
https://github.com/kvsaiakhil/triple_fp_units
```

### 16. Check README status and content

```text
can you a diff of readme from repo and the current folder
```

### 17. Ask for diagrams

```text
Where is the block diagram?
```

### 18. Create per-unit block diagrams and improve README

```text
Now, create a ablock diagram for each fp unit we implemented and create a neat, detailed, user friendly readme.md
```

### 19. Add tool installation and run instructions

```text
Also, now add the steps to install tools, and how to run and verify each implementation
```

### 20. Commit and push documentation updates

```text
go ahead and commit and push changes
```

### 21. Add bug report and command dump

```text
Create two files

1. one is bug report we have encounterd till now, fixes
2. also create a dump file of all the commands i used

commit the changes, and push the changes
```

### 22. Feasibility of a new 4-operand unit

```text
Now, create another unit with 4 fp operands and same constraints called "triple multiple and add", is it feasable first? can you build it using existing submodules? what do you think?
```

### 23. Confirm implementation direction for the 4-operand unit

```text
Yes, go ahead reuse existing infrastructure and build a new custom raw core from scratch while keeping the same pipeline contract,
```

### 24. Add bug/command updates for the new unit

```text
add the bug reports and commands to the respective file
```

### 25. Add a full prompt-history file

```text
Also create another file with all the prompts i used to build the whole project from start to finish
```

## Scope Evolution Summary

The overall prompt flow moved through these phases:

1. BOOMv3 RTL exploration
2. FMA-only architecture understanding
3. standalone triple-op feasibility study
4. triple-add and triple-multiply RTL/spec/verification implementation
5. deeper HardFloat-backed verification and bug fixing
6. reusable UVM-lite verification scaffolding
7. Python reference/debug-model development
8. project documentation and Git publishing
9. expansion to the new 4-operand `a*b*c+d` unit
10. project audit-trail completion with bug, command, and prompt histories

## Related Audit Files

- [BUG_REPORT_AND_FIXES.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/BUG_REPORT_AND_FIXES.md)
- [COMMAND_HISTORY_DUMP.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/COMMAND_HISTORY_DUMP.md)
- [PROJECT_SUMMARY.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/PROJECT_SUMMARY.md)
