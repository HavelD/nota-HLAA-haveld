# HLAA - Nota - Havel Daniel - Homework solutions 

## Project name: **nota_havel_hlaa**

Solution of my homeworks for HLAA. Each solution was tested and have widget to show its correctness. All

---
---
Click to open information about Task completion and provided solution and its files

<details>
<summary>Task: Sandsail2</summary>

### Behaviour: ***Sandsail*** <img src="BETS/projects/nota_havel_hlaa/Behaviours/Sandsail.png" alt="sandsail icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Solution results
    - infolog_sandsail2.txt
- Delopment files
    - Behaviours
        - Sandsail.json (main behaviour)
    - Sensors
        - havelFormationDefinition.lua (line formation)
        - CommanderWindArrow.lua (widget data sender)
    - UnitCategories
        - commander.json
    - Widgets
        - dbg_arrowWidget.lua

#### Solution:
- Using Wind()
- Custom formation definition (line)
- Formation project commands
- Role definition + role action split for commander and others

#### Widget:
- Current direction of wind with strength (effecting the length and number of arrows)

![Sandsail screenshot with shown Widget and Formation](/Homework%20Documents/sandsail_solution.png)

</details>

---

<details>
<summary>Task: CPT2</summary>

### Behaviour: ***CTP2*** <img src="BETS/projects/nota_havel_hlaa/Behaviours/CTP2.png" alt="CTP2 icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Solution results
    - infolog_ctp2.txt
- Development files
    - Behaviours
        - CTP2.json (main behaviour)
    - Sensors
        - AbsolutePointsToFormation.lua (Formation creation)
        - Peaks.lua (Find Hills)
        - widgetHelpHills.lua (widget data sender)
    - Widgets
        - dbg_hills.lua

#### Solution:
- Custom sensors
    - Peaks
        - Find local maxima and plateaus - with some or none minimal threshold
        - Calculation of middlepoint of every local zone (using Flood Fill algo)
        - Removal of peaks closest to specified list of points (e.g. enemy positions)
    - AbsolutePointsToFormation
        - Takes list of absolute points that the group should spread to and creates a formation that is defined as such each unit will reach its destination before the formation finishes its action. (Finds nearest unit from furthest path to set him as leader)
        - If set as parameter, when more units are given then there are positions in formation - sends multiple units to same location - failproofing
- Select all units and run behavior. Sensors calculate highest points and MissionInfo reveals enemy position. Remove hill with the enemy and conquer other three hills.

#### Widget:
- Height map of whole area with Colorcoding for: $\color{Gray}{\textsf{Low ground}}$, $\color{Purple}{\textsf{Above Threshold}}$, $\color{Orange}{\textsf{Local Maxima (or Plateau) above threshold}}$, $\color{Red}{\textsf{Centroid of each local Maxima}}$.

*(NOTE: This behaviour does not show its behaviour icon on my machine, don't know why.)*

![Sandsail screenshot with shown Widget and Formation](/Homework%20Documents/ctp2_solution.png)

</details>

---

<details>
<summary>Task: TTDR</summary>

### Behaviour: ***TTDR-Multi*** <img src="BETS/projects/nota_havel_hlaa/Behaviours/TTDR-Multi.png" alt="TTDR-Multi icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Solution results
    - infolog_ttdr.txt
- Development files
    - Behaviours
        - TTDR-Multi.json (main behaviour)
        - SearchArea.json (Air Vision units line trough map)
        - SafelyTransport.json (Behaviour for one transporter unit and one (tower/unit))
    - Commands
        - FollowPath.lua
        - LoaderCommand.lua
    - Sensors
        - Peaks.lua (Using HeightMap to find safe spots)
        - FindSafePath.lua (Route from A to B using safe map)
        - havelFormationDefinition (For flying with Vision aircrafts)
        - ListClosestUnitsByCategory (Unit lists)
        - ReverseTable.lua (reversing path A->B to B->A)
        - widgetHelpPath.lua (widget data sender)
    - UnitCategories
        - AirVision.json (Observatory flying units)
        - towers.json (find WTC)
        - ttrd_groundUnits.json (mobile ground units)
    - Widgets
        - dbg_hills.lua (show Height Map - turned of for now but should work okay)
        - dbg_path.lua (Show Current path a unit will take)

#### Solution:
- Multiple actions simultaneously
    - Air Vision units fly in line trough whole map to gain knowledge about enemy positions (Afterall not used in decision-making)
    - Ground units (closest 11) go by foot to safe area
    - Closest 13 Towers are located and picked up by Air transporters (in group of five)
1. Evaluate Map
    1. find height of every point. Set threshold.
    1. Make "safe spot" grid (green) - where area heights are under threshold and are not reachable (and visible) by enemy guns on mountains
1. Each transporter get next tower in queue to be saved.
    1. Find closest point (A) of safespots to transporter 
    1. Find closest point (B) of safespots to Tower.
    1. Find shortest path from A to B using BFS in binary safespot grid.
    1. Plan route: Transporter Position, Path (A->B), Load Tower, Reverste Path (B->A), center of the safe area
1. In loop check if mission condition is met, end if yes,
- A Subtree behaviour is created - 

#### Widget:
- Path display of unit (red line from A to B using safe spot) + safespots - point on map considered as safe (just based on height - it is not updated on enemy encounter as it was not needed for base points.)
- Height map of whole area (currently turned of for more clearence - well used in development)

*(NOTE: In the task description there is requirement that only two input parameters can exist. In SafelyTrasnport behaviour I have three but it could be change to two just using variable instead of UnitID (table with multiple values) or I could remove "destination parameter and throw it into main subtree - I decided not to just because this looks cleaner. I hope it won't be problem")*

![Sandsail screenshot with shown Widget and Formation](/Homework%20Documents/ttdr_solution.png)

</details>

---
## Found bug/problems
1. When creating new behavioral tree, probably the indexes are not updated for the list of trees. Using reference of given tree in another tree (without a restart of a game right after creation) causes that on start of that behaviour it will reference different subtree that it should. 
1. Phishing link in spring documentation
        • On the website https://springrts.com/wiki/Lua:WidgetDirectory tbere is link that takes you to some advertisements only: "[Lua Category on Springfiles.com](http://springfiles.com/spring/lua-scripts)"
1. Sensors with underscore in filename are ignored by the game.

