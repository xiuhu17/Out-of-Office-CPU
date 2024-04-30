# ECE425: mp3 README

**This document, `README.md`, forms the specification for the machine problem. For a more comprehensive summary, see [GUIDE.md](./GUIDE.md).**

## Standard Cell Library

You will package your standard cell library from MP1 into a format that auto PnR tools can recognize:
Liberty Timing file (`.lib`) and Library Exchange Format (`.lef`).

This will be used in the following parts.
If you do not wish to use your own standard cell library, we provided (a bad) one for you.

Files needed to be submitted for this part:
- standard cell library, `stdcells.lib` and `stdcells.lef`.

## Auto PnR Controller

You will use the auto PnR tool to layout your controller using your standard cell library.

A skeleton of a script is provided. You will complete it and use it to PnR the controller.

Files needed to be submitted for this part:
- Innovus project saved files, `controller.dat`.
- Innovus script used for this part: `controller.tcl`.
- screenshot of the Innovus window when the auto PnR is done, `controller.png`.

## Controller and Datapath Integration

You will import this controller back into Virtuoso and integrate it with your datapath.

Files needed to be submitted for this part:
- screenshot of your completed integrate design, `integration.png`.

## Auto PnR Full CPU with only standard cell

You will use the auto PnR tool to layout the entire CPU (controller+datapath).

You will modify the script from the previous part and use it here.

Files needed to be submitted for this part:
- Innovus project saved files, `cpu1.dat`.
- Innovus script used for this part:, `cpu1.tcl`.
- screenshot of the Innovus window when the auto PnR is done, `cpu1.png`.

## Auto PnR Full CPU with your register file

You will package your register file from MP2 into a `lib` and `lef`.

You will replace the register file in the reference CPU with the register file IP you packaged.

You will modify the script from the previous part and use it here.

Files need to be submitted for this part:
- `regfile.lib` and the `.regfile.lef` file.
- Innovus project saved files, `cpu2.dat`.
- Innovus script used for this part:, `cpu2.tcl`.
- screenshot of the Innovus window when the auto PnR is done, `cpu2.png`.

## Grading

### Submission

Submit a zip file to canvas with the following structure:

```
submission.zip
├── stdcells.lib
├── stdcells.lef
├── controller.dat
│   └── ...
├── controller.tcl
├── controller.png
├── integration.png
├── cpu1.dat
│   └── ...
├── cpu1.tcl
├── cpu1.png
├── refile.lib
├── refile.lef
├── cpu2.dat
│   └── ...
├── cpu2.tcl
└── cpu2.png
```

### Rubric

This assignment is graded out of 16 points and floored at 0 points.

Point distributution among parts is as follows:

| Part                       | Points |
|---|---|
| Standard Cells             | 3 |
| Controller                 | 5 |
| Integration                | 1 |
| Full CPU                   | 4 |
| Full CPU with regfile      | 3 |

Extra credit is awarded based on the area of the full CPU with your custom register file:

| Place            | Points |
|---|---|
| 1st              | +3 |
| 2nd-5th          | +2 |
| 6th-15th         | +1 |
| 16th-last        | +0 |
