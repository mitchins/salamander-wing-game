import os
from PIL import Image, ImageDraw
import random

OUTPUT_DIR = "materials/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def save_image(img, name):
    path = os.path.join(OUTPUT_DIR, name)
    img.save(path)
    print(f"Generated {path}")

def generate_metal_pattern():
    size = 64
    img = Image.new('RGB', (size, size), color=(180, 180, 180))
    draw = ImageDraw.Draw(img)
    
    # Draw some "panel lines"
    draw.line([(0, 0), (size, 0)], fill=(100, 100, 100), width=2)
    draw.line([(0, 0), (0, size)], fill=(100, 100, 100), width=2)
    draw.line([(size/2, 0), (size/2, size)], fill=(140, 140, 140), width=1)
    draw.line([(0, size/2), (size, size/2)], fill=(140, 140, 140), width=1)
    
    # Draw "rivets"
    for x in [4, size-4, size/2-4, size/2+4]:
        for y in [4, size-4, size/2-4, size/2+4]:
            draw.point((x, y), fill=(50, 50, 50))
            
    # Add some noise
    pixels = img.load()
    for i in range(size):
        for j in range(size):
            r, g, b = pixels[i, j]
            noise = random.randint(-20, 20)
            pixels[i, j] = (max(0, min(255, r + noise)), 
                            max(0, min(255, g + noise)), 
                            max(0, min(255, b + noise)))
    
    save_image(img, "tex_pattern_metal.png")

def generate_checker_pattern():
    size = 64
    img = Image.new('RGB', (size, size), color=(255, 255, 255))
    pixels = img.load()
    check_size = 8
    
    for i in range(size):
        for j in range(size):
            if ((i // check_size) + (j // check_size)) % 2 == 0:
                pixels[i, j] = (200, 200, 200) # Light grey
            else:
                pixels[i, j] = (50, 50, 50) # Dark grey
                
    # Add noise
    for i in range(size):
        for j in range(size):
            r, g, b = pixels[i, j]
            noise = random.randint(-10, 10)
            pixels[i, j] = (max(0, min(255, r + noise)), 
                            max(0, min(255, g + noise)), 
                            max(0, min(255, b + noise)))

    save_image(img, "tex_pattern_checker.png")

def generate_grid_pattern():
    size = 64
    img = Image.new('RGB', (size, size), color=(20, 20, 20))
    draw = ImageDraw.Draw(img)
    
    # Grid lines
    step = 16
    for i in range(0, size, step):
        draw.line([(i, 0), (i, size)], fill=(100, 100, 100), width=1)
        draw.line([(0, i), (size, i)], fill=(100, 100, 100), width=1)
        
    # Border
    draw.rectangle([(0,0), (size-1, size-1)], outline=(150, 150, 150), width=2)
    
    save_image(img, "tex_pattern_grid.png")

def generate_noise_pattern():
    size = 64
    img = Image.new('RGB', (size, size))
    pixels = img.load()
    
    for i in range(size):
        for j in range(size):
            val = random.randint(100, 255)
            pixels[i, j] = (val, val, val)
            
    save_image(img, "tex_pattern_noise.png")

def generate_thruster_gradient():
    size = 64
    img = Image.new('RGBA', (size, size), (0,0,0,0))
    pixels = img.load()
    center = size / 2
    max_dist = size / 2
    
    for i in range(size):
        for j in range(size):
            dist = ((i - center)**2 + (j - center)**2)**0.5
            if dist < max_dist:
                alpha = int(255 * (1 - dist/max_dist))
                # White center, fading to transparent
                pixels[i, j] = (255, 255, 255, alpha)
                
    save_image(img, "tex_thruster_gradient.png")

if __name__ == "__main__":
    generate_metal_pattern()
    generate_checker_pattern()
    generate_grid_pattern()
    generate_noise_pattern()
    generate_thruster_gradient()
