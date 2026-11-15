---
name: responsive-game-layout
description: >-
  Keep game scenes, HUD and input mapping usable across display sizes, orientation changes,
  safe areas and different input devices.
---

# Responsive Game HUD and Canvas Layout

Identify supported aspect ratios, orientation changes and input modes. Decide whether the game world fits, crops or expands across them. Record minimum visible world bounds, HUD priorities, safe-area treatment and fallback for cramped widths. Treat the world camera and screen HUD as separate layout layers.

## Set coordinate boundaries

Choose a reference resolution and describe how camera and UI scale independently. Anchor HUD groups to meaningful safe-area edges. Use fixed logical spacing for nearby controls and clamp to readable sizes. Keep status bars and action prompts visible in narrow and wide variants. Collapse secondary details into an intentional screen or action when space is insufficient. Validate text at the longest supported translation and with enlarged text if the game offers it.

In Unity UI, confirm the Canvas Scaler's reference resolution and screen-match behavior against the current package. Use the correct canvas and camera for coordinate conversions. In a browser canvas, distinguish client pixels, canvas drawing-buffer pixels and world coordinates. Account for the actual bounding rectangle, device pixel ratio and letterbox margins before computing world positions.

## Keep input aligned

For a fitted 800 × 450 scene displayed within a 1,000 × 600 area, the scale is 1.25 with 18.75 vertical pixels above and below. Subtract the active content origin and divide by scale for logical pointer position. Confirm touches in the letterbox area do not trigger world actions. Use equivalent mapping for selections near screen edges. Recompute after a resize or orientation change and verify ongoing drags follow the documented cancellation or remapping policy.

Keep controller focus order predictable after HUD rearrangement. Verify touch controls can be reached without overlapping critical information. When browser or engine safe-area data is available, test on a device or emulator with an asymmetric inset and compare against its actual coordinate system.

## Verify the display matrix

Test a narrow and wide viewport, portrait or rotated device where supported, a safe-area cutout and an enlarged scale. Capture screenshots, active content rectangle, world visibility and input outcomes for each. Verify a point in the rendered target maps to the expected game object. Check pause menu, HUD prompts and gameplay independently after resize. Record any unsupported shape explicitly so a failed test cannot be mistaken for an accepted fallback.

## Sources

- Unity Canvas Scaler

- Unity RectTransformUtility

---
Source: SkillDB game-design-skills pack (https://skilldb.dev/skills/game-design-skills/responsive-game-layout)
