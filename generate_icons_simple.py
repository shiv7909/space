#!/usr/bin/env python3
"""
Generate notification icon PNGs - simple version without font dependency
"""
from PIL import Image, ImageDraw
import os

def create_notification_icon(size):
    """Create a bold "S" notification icon"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw black circle background
    margin = int(size * 0.08)
    draw.ellipse([margin, margin, size - margin, size - margin], fill=(0, 0, 0, 255))

    # Draw bold "S" using rectangles and arcs
    center_x = size // 2
    center_y = size // 2
    s_width = int(size * 0.3)
    s_height = int(size * 0.5)

    # Top curve of S
    draw.rectangle([center_x - s_width//2, center_y - s_height//2,
                    center_x + s_width//2, center_y - s_height//2 + int(s_height*0.25)],
                   fill=(255, 255, 255, 255))

    # Top right curve
    draw.pieslice([center_x, center_y - s_height//2,
                   center_x + s_width, center_y - s_height//2 + int(s_height*0.3)],
                  0, 180, fill=(255, 255, 255, 255))

    # Middle bar
    draw.rectangle([center_x - s_width//2 + int(s_width*0.1), center_y - int(s_height*0.08),
                    center_x + s_width//2 - int(s_width*0.1), center_y + int(s_height*0.08)],
                   fill=(255, 255, 255, 255))

    # Bottom left curve
    draw.pieslice([center_x - s_width, center_y + s_height//2 - int(s_height*0.3),
                   center_x, center_y + s_height//2],
                  180, 360, fill=(255, 255, 255, 255))

    # Bottom curve of S
    draw.rectangle([center_x - s_width//2, center_y + s_height//2 - int(s_height*0.25),
                    center_x + s_width//2, center_y + s_height//2],
                   fill=(255, 255, 255, 255))

    return img

# Create output directories
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-mdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-hdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxxhdpi", exist_ok=True)

densities = {
    'drawable-mdpi': 48,
    'drawable-hdpi': 72,
    'drawable-xhdpi': 96,
    'drawable-xxhdpi': 144,
    'drawable-xxxhdpi': 192,
}

print("🎨 Generating notification icons with bold S...")

for density, size in densities.items():
    img = create_notification_icon(size)
    output_path = f"D:\\habitz\\android\\app\\src\\main\\res\\{density}\\ic_notification.png"
    img.save(output_path)
    print(f"✅ {density}: {size}x{size}")

print("\n✅ All notification icons generated!")

