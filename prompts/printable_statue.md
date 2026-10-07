# Prompt formula: a printable statue image

TRELLIS.2 (or Pixal3D) builds the 3D model from this one image, so write the image for the printer, not for the camera.

## The formula

1. **Single compact subject.** One statue, one piece. Two subjects fuse into one mesh.
2. **Base built into the image.** The subject stands or sits on a plinth or rock. It gives you a flat bottom to put on the build plate.
3. **No hair-thin freestanding parts.** Thin spikes, antennas and floating bits break off or disappear in the mesh. Think chunky.
4. **"Taller than it is wide."** Name the proportion. It keeps the subject compact and fills a square frame.
5. **Full object visible, with margin.** Bottom of the base to the top of the subject, nothing cropped, a small margin on all sides.
6. **Plain backdrop.** A seamless studio background makes background removal clean.
7. **Rim light.** A subtle rim light separates a dark subject from the backdrop. Soft key light, no harsh shadows.
8. **"Uniform unpainted resin, no color."** A print has no texture. Colour only adds noise to the shape.

## The dragon prompt from the video

```
A photorealistic studio product photograph of a highly detailed collectible dragon statue, sculpted as a single unpainted piece in uniform matte dark grey resin with a faint warm metallic sheen, no paint and no color accents anywhere. The statue is clearly taller than it is wide.

A massive, heavy-set dragon sits upright on top of a tall craggy rock that reaches about half the height of the statue, its broad chest and coiled, muscular body pressed against the stone and its front claws gripping the rock's edge. Its thick scaled neck rises in a tight S, and its head is turned to the left in three-quarter view with a fierce expression, slightly open jaws with small fangs, and a crown of long backward-sweeping horns and spiky frills. Two large bat-like wings rise steeply, almost vertically, close behind the body: the wing arms point upward and curl inward at the top into hooked claws, and the membranes with fine vein and leather texture fan down from the wing arms to the dragon's back, with the wing tips hanging down no wider than the edge of the plinth. The body is covered in overlapping scales with ridged belly plates, and a long, thick spiked tail curls down around the front right of the rock onto the plinth.

The foot of the rock is densely packed with gothic ruins: a carved arched doorway in the center, a second small arched shrine on the right, a short gothic spire rising from a chapel ruin on the right just below the right wing tip, broken fluted columns lying on the ground, a small treasure chest on the left, two human skulls, and heaps of rubble filling the space between them. Everything stands on a compact round display plinth with an ornate engraved band around its edge.

The full statue is centered and completely visible from the bottom of the plinth to the wing tips, with a small margin on all sides and nothing cropped. Straight-on front view with the camera level with the dragon's chest, 85 mm lens, sharp focus from front to back. Soft key light from the upper left, a subtle rim light separating the dark silhouette from the background, plain dark charcoal seamless studio backdrop with a gentle gradient. Crisp micro detail on scales, horns and carvings, high-end miniature statue product shot.
```

## Settings

- [`workflows/PixelArtistry_Print_00_Image_Qwen.json`](../workflows/PixelArtistry_Print_00_Image_Qwen.json) (Qwen-Image 2.1 text-to-image)
- **2048 × 2048** (1:1, 4 megapixels)
- cfg **1**
- seed **447606998181495**
- 50 steps, euler / simple, prompt enhancer (`refine_prompt`) off
- Models: `qwen_image_2.1_int8_convrot`, `qwen3vl_8b_int8_convrot`, `qwen_image_2.1_vae_bf16`

The workflow's own defaults are 25 steps and seed 0. Dragging `examples/dragon_front.png` into ComfyUI loads the dragon setup (50 steps, the seed above).

The same seed only reproduces the same image with the same model files, steps and sampler. If your result looks different, check those first.

The finished image is in [`examples/dragon_front.png`](../examples/dragon_front.png). The workflows load it by default.
