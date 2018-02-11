# Augmented Reality Exploration with ARKit

An undergraduate research project exploring the capabilities of ARKit for the Virginia Tech Department of Computer Science.

The research comprises two tutorials, a semester-long project, and a research website containing literature review and documentation of the semester project's features.

## Tutorials
### [Hello World](http://patrickgatewood.com/arkit-research/tutorials/arkit-hello-world/tutorial.html)
Learn how to create your first ARKit application. Includes step-by-step instructions, code samples, and the [completed sample application](./apps/Hello-World-AR).

#### Learning Objectives
* ARKit basics
* Horizontal plane detection
* SceneKit

### [SceneKit Models and Physics](http://patrickgatewood.com/arkit-research/tutorials/models-and-physics/tutorial.html)
Builds on the Hello World tutorial. Learn how to render a 3D SceneKit model in ARKit and apply physics to the rendered models. View the [completed application](./apps/Models-and-Physics-AR), or [follow the tutorial](http://patrickgatewood.com/arkit-research/tutorials/models-and-physics/tutorial.html) to develop it yourself!

#### Learning Objectives
* Handling user interaction in ARKit
* Adding 3D virtual content to an ARSCNView
* Applying physics to rendered Models
* Detecting collision with SCNPhysicsBodies
* Saving memory to optimize performance

## Semester Project: VTQuest-AR
VTQuest-AR serves as a companion app for the Virginia Tech campus. The app's  augmented reality experience overlays information about [VT Buildings](https://vt.edu/about/buildings.html). By pointing the camera at a building, the user can see additional information about what's in front of them. The building details will render in the building's actual physical location as the app translates the building's lat/long coordinates into localized coordinates in the ARSCNView.

## Documentation
You can view the full documentation on the [research website](http://patrickgatewood.com/arkit-research/research-intro.html).
