# Distance Transform Demo
---------------------------------------
Seminary project, Geometry of Discreet Spaces, Faculty of Technical Science, Novi Sad, Serbia.

Implementation and demonstration of Rosenfeld and Pfaltz two-pass distance transform algorithm[1].

## Demo program

Demo program has two sub-programs:
- animation
- visualization

**Animation** is designed to demonstrate how the algorithm operates. It steps throught the input image, which is generated to have a square hole in the middle, and shows how the distance value is computed in current pixel (matrix field). Here is an example of the demo (`> ./dtdemo -p animation -w=30`):

![demo](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/dtdemo.gif?raw=true)

**Visualization** works with an arbitrary image (which is easily binarizer), uses it and shows in the similar fashion to the animation sub-program, how distance transform is evaluated. Say, using an image like this:

![deer-input](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/deer-input.png?raw=true)

Performs distance transforms, visualizes algorithm evaluation step-by-step, and finally shows the result:

![deer-distance](https://github.com/ljubobratovicrelja/distance-transform/blob/master/images/deer-distance.png?raw=true)

-----------------------------------------
[1] Rosenfeld, A and Pfaltz, J L. 1968. Distance Functions on Digital Pictures. Pattern Recognition, 1, 33-61.
