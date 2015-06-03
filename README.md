# see_simple - Simple Simulink to Ecore Exporter

see_simple is a simple tool to export an abstract view of a Simulink model into Eclipse (EMF). The abstract view is an XML file that conforms to an Ecore meta-model for Synchronous-Reactive systems. The Ecore view preserves all the structural properties of the Simulink model, such as the types and interfaces of the blocks and the connections among the blocks, and also accounts for the information related to the timed execution events, including rate and partial order of execution constraints.

*The Ecore meta-model is not currently available as ready-to-use EMF plugin. Please refer to [this paper] (http://retis.sssup.it/~marco/papers/2014/etfa.pdf) for a description of the meta-model schema*.

# Install

To install see_simple simply adjust the `MATLABPATH` to include this directory _and_ its subdirectories.

Assuming `path/to/see/simple` is the path to the directory that contains this `README.md` file, simply give the following command at the Matlab prompt:
```
>> addpath(genpath('path/to/see/simple'))
```

For more information about the Matlab Search Path and on how to use the modified Search Path in future sessions, please refer to the following web links:  
http://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html  
http://www.mathworks.com/help/matlab/ref/savepath.html

# Getting Started

There are three example models in `see_simple/Tests`. To generate the XML view for one model, (i) open the model and (ii) launch the `slx2emof` script.

`Example2` is a simple model structured as robot arm inverse kinematics algorithm, but it *does not implement any real functionality*. `ies_DCMotorControl.slx` implements a DC Motor Speed Digital Controller inspired to [this example] (http://ctms.engin.umich.edu/CTMS/index.php?example=MotorSpeed&section=ControlDigital). It has a companion Matlab binary file (`DCMotorControlSetup.mat`) that initializes a number of model parameters. Load the binary file before running the `slx2emof` script
```
>> load('Tests/DCMotorControlSetup.mat');
>> open('Tests/ies_DCMotorControl.slx');
>> run('slx2emof.m'),
```

# Note on licensing

see_simple is released under the terms of the permissive, industry-friendly 3-Clause BSD License. It includes a third-party function to find out which blocks are involved in any direct feedthrough paths. The function is copyright to MathWorks Support Team, and is publicly available from [this link] (http://www.mathworks.com/matlabcentral/answers/102619-how-can-i-highlight-the-direct-feedthrough-paths-in-simulink).
