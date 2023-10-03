I did this repo to replicate the issue we are having with Lune step-by-step.

Steps:
- I created this place ID 14951199180 as main (https://www.roblox.com/games/14951199180/Lune-Example-Main). 
- Then I created a blank place DEV-A 14951211089 (https://www.roblox.com/games/14951211089/Lune-Example-DEV-A)
- Pulled the place from MAIN and transformed into files in my repository using this script https://github.com/Quenix/lune-workflow-example/blob/main/build/scripts/pull-changes-from-place.lua.
- Commit to git: https://github.com/Quenix/lune-workflow-example/commit/6e3307c3afdfe929680828c876caf38115f49eac
- Used sync script to push files into DEV-A using this script: https://github.com/Quenix/lune-workflow-example/blob/main/build/scripts/sync.lua.
- Pulled the files again from Dev-A and this is what I've got: https://github.com/Quenix/lune-workflow-example/commit/ec6f9f9ab672e3f35997eee30d3b8f994f1289fa

This latest commit represents the issue with the floating points. Basically I synced MAIN into DEV-A and pulled again right after directly from DEV-A. 

Expected result: No changes on git to commit, since I pulled right after publishing over it
What I've got: A few changes with the floating point issue.
