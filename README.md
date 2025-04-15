# Evacuation Simulation in NetLogo

This document provides an implementation of the evacuation simulation described in the study [Evacuation Simulation Study](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=9766303&utm_source=sciencedirect_contenthosting&getft_integrator=sciencedirect_contenthosting). 
It explains how to use the NetLogo interface for the simulation and the assumptions made during its implementation.

## Interface Explanation

- **Setup**: Recognizes patches based on their color, assigns indices to doors, and calculates exit-energy. Note that this method is slow; ensure the simulation speed is set to maximum before running it to avoid long wait times.
- **Setup-Person**: Generates individuals on "floor" patches within the defined area (x-min, x-max, y-min, y-max). In the paper, individuals do not spawn randomly on the map.
- **Go-Once**: Advances the simulation by one tick.
- **Go**: Continuously calls `go-once` until no individuals remain.
- **With-Assist**: Implements the assisted evacuation as described in the paper.
- **Percentages**: Self-explanatory.
- **Place-Staff**: When activated, places a staff member on the patch you click, if available. Note that if the speed is set to maximum, individuals will only appear when you deactivate the feature. Reduce the speed to see the changes in real-time.
- **Remove-Person**: When activated, allows you to click on individuals to remove them. Removing an assisted individual will also remove their associated helper.
- **Color Palette**: The six colors at the top right correspond to the objects: door, floor, wall, obstacle 1, obstacle 2, and obstacle 3. If you import a map, change the colors to match your objects before running `setup`.
- **Draw**: When activated, changes the color of the patch you click to the `draw-color`. This allows you to close doors by changing their color to an obstacle, avoiding the need to recreate the image.
- **Coordinate Boundaries (xmin, xmax, ymin, ymax)**: Define the area within which individuals can spawn.

## Assumptions

The following assumptions were made due to the lack of specific details in the article:

- **Percentage of Participants Choosing the Nearest Exit**: Instead of setting a fixed number of individuals choosing the correct door, each individual has a probability of choosing the correct door (set to 90%). This approach leverages the law of large numbers, ensuring that the expected behavior is achieved with a large group.
- **With-Assist Implementation**: The paper only specifies that an assisted individual has an associated adult nearby. Therefore, I implemented it such that whenever a child or disabled individual spawns with `with-assist` enabled, an adult spawns on a neighboring patch (if available).

## Testing a Map

To test a map:

1. Define the map size according to your image dimensions.
2. Import the image using "Import Patch Colors" (not in RGB mode).
3. Adjust the input colors to match the patch colors (within a tolerance of ±1).
4. Modify the coordinate boundaries (xmin, xmax, ymin, ymax) to define the spawn area for individuals.
5. Run `setup`.
6. Adjust parameters and add staff as needed.
7. Run `go` to start the simulation.

For more details, refer to the study: [Evacuation Simulation Study](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=9766303&utm_source=sciencedirect_contenthosting&getft_integrator=sciencedirect_contenthosting).
