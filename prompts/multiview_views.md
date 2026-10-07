# Multiview: back, left and right view prompts

These are the three prompts from the **Step 2** Edit nodes in `workflows/PixelArtistry_Print_04_Multiview.json`. They are written for the dragon. Change the object-specific parts when you use your own image.

Pixal3D reads the views as front / left / back / right at fixed 90° steps. The front image is your own (`examples/dragon_front.png` for the dragon).

## Rules

1. **Back first.** Generate the back from the front, then use front + back as references for left and right so all views agree.
2. **Left** = the object's left side. Its front faces the **left edge** of the image.
3. **Right** = its front faces the **right edge**.
4. **A 180° orbit swaps left and right.** A part on the right in the front view is on the left in the back view.
5. **Count what must not be duplicated.** Say "exactly one tail", "exactly two wings". The model invents extras otherwise.
6. **"Exact side profile, not a three-quarter view."** Three-quarter views warp the mesh.
7. **Same backdrop as the front.** Use the same plain backdrop wording, so background removal treats all four views alike.
8. Say what is in the **foreground** of each side view.
9. Keep `refine_prompt` **off**. The enhancer softens "exact 90°" into a nicer angle.

## Back view (`<image1>` = front)

```
Show the statue in <image1> from directly behind: the camera orbits exactly 180° around the static statue at the same height and distance. Keep everything identical: the same dragon, rock, ruins and round plinth, the same matte dark grey resin material, the same scale and position in the frame, the same lighting and the same plain dark charcoal seamless backdrop. From behind we see the dragon's back with the ridge of spikes running down its spine, the backs of both raised wings with their wing bones, and the back of its horned head. The dragon has exactly one tail: it starts at the base of the spine and curves around the left side of the rock toward the front. The gothic spire and its chapel ruin are now on the left side of the image, and there is no spire on the right side. The back of the rock is rough craggy stone, with scattered rubble on the plinth. The whole statue is visible from the bottom of the plinth to the wing tips, nothing cropped.
```

## Left view (`<image1>` = front, `<image2>` = generated back)

```
<image1> shows the front and <image2> the back of the same statue. Show the statue from its left side: the camera orbits exactly 90° around the static statue at the same height and distance, an exact side profile, not a three-quarter view. The statue's front, with the arched doorway and the dragon's chest, faces the left edge of the image, and its back faces the right edge. The gothic spire and its chapel ruin are in the foreground, closest to the camera; the treasure chest is hidden behind the rock. Both raised wings are seen from the side, one behind the other, and the dragon's single spiked tail runs along the near side of the rock. Keep everything identical: the same proportions, scale and position in the frame, the same matte dark grey resin material, the same lighting and the same plain dark charcoal seamless backdrop. The whole statue is visible from the bottom of the plinth to the wing tips, nothing cropped.
```

## Right view (`<image1>` = front, `<image2>` = generated back)

```
<image1> shows the front and <image2> the back of the same statue. Show the statue from its right side: the camera orbits exactly 90° around the static statue at the same height and distance, an exact side profile, not a three-quarter view. The statue's front, with the arched doorway and the dragon's chest, faces the right edge of the image, and its back faces the left edge. The treasure chest is in the foreground, closest to the camera; the gothic spire is on the far side, partly hidden behind the rock and the dragon. Both raised wings are seen from the side, one behind the other. Keep everything identical: the same proportions, scale and position in the frame, the same matte dark grey resin material, the same lighting and the same plain dark charcoal seamless backdrop. The whole statue is visible from the bottom of the plinth to the wing tips, nothing cropped.
```

## Template for your own object (back view)

```
Show the object in <image1> from directly behind: the camera orbits exactly 180° around the static object at the same height and distance. Keep everything identical: the same [material], the same scale and position in the frame, the same lighting and the same plain [color] backdrop. From behind we see [what the back shows]. [Count anything that must not be duplicated.] [Parts that are now on the other side.] The whole object is visible, nothing cropped.
```

## Settings used in the workflow

- custom size **on**, **2048 × 2048** (Step 3 crops each view to 1024² for Pixal3D)
- reference `resolution` **1024**
- 25 steps, cfg 1, euler / simple, `refine_prompt` **off**
- Each view has its own fixed seed. A bad view: change only its seed and run again.
