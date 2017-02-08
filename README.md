# Distance Transform Demo
---------------------------------------
Seminary project, Geometry of Discreet Spaces, Faculty of Technical Science, Novi Sad, Serbia.

Implementation and demonstration of Rosenfeld and Pfaltz two-pass distance transform algorithm[1].

## Demo program

Demo program has two sub-programs:
- animation
- visualization

## Animation

...Is designed to demonstrate how the algorithm operates. It steps throught the input image, which is generated to have a square hole in the middle, and shows how the distance value is computed in current pixel (matrix field). Here is an example of the demo (`> ./dtdemo -p animation -w=30`):

![demo](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/dtdemo.gif?raw=true)

## Visualization

...Works with an arbitrary image (which is easily binarized), uses it and shows in the similar fashion to the animation sub-program, how distance transform is evaluated. Say, using an image like this:

![deer-input](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/deer-input.png?raw=true)

Performs distance transforms, visualizes algorithm evaluation step-by-step, and finally shows the result:

![deer-distance](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/deer-distance.png?raw=true)

# Compilation

Program is written using D programming language, by utilizing following libraries:
- [dcv](https://github.com/libmir/dcv) (computer vision library)
- [derelict-ft](https://github.com/DerelictOrg/DerelictFT) (freetype wrapper for D language)

It is compiled using D's project manager application, *dub*. Currently is only tested on MacOS Sierra operating system. [LDC compiler v1.1.0](https://github.com/ldc-developers/ldc/releases/tag/v1.1.0) is required. Compile the project with folliwing command:

```
> dub build --build=reelase --compiler=ldc2
```

# Using

To define the sub-program (animation, visualization), use the `-p` flag:

```
./dtdemo -p animation
./dtdemo -p visualization
```

Each of sub-programs has elaborated *help* content, when `-h` flag is added:
```
> ./dtdemo -p animation -h

Distance Transform Animation.
-s            --size Size of the binary image used in the demo.
-b          --border Border size (cell count).
-c --cell-resolution Resolution (pixel size) of the matrix cell in the demo.
-m          --margin Margin in animation drawing.
-w       --wait-time Wait time between each algoritm step in the demo.
-r     --demo-result Result type of the demo (show, or write). If write, output must be given.
-o          --output Output path.
-h            --help This help information.
```

-----------------------------------------
[1] Rosenfeld, A and Pfaltz, J L. 1968. Distance Functions on Digital Pictures. Pattern Recognition, 1, 33-61.
