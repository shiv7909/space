#!/usr/bin/env python3
"""
Generate notification icon PNGs with bold "S" in white on black background
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_notification_icon(size):
    """Create a notification icon of given size"""
    # Create image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw black circle background
    margin = int(size * 0.08)
    circle_box = [margin, margin, size - margin, size - margin]
    draw.ellipse(circle_box, fill=(0, 0, 0, 255))

    # Draw white "S" with bold font
    try:
        # Try to use Arial Bold
        font_size = int(size * 0.65)
        font = ImageFont.truetype("C:\\Windows\\Fonts\\ArialBD.ttf", font_size)
    except:
        try:
            font_size = int(size * 0.65)
            font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", font_size)
        except:
            font = ImageFont.load_default()

    # Draw white "S" centered
    text = "S"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (size - text_width) // 2
    y = (size - text_height) // 2

    draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

    return img

# Ensure directories exist
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-mdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-hdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxxhdpi", exist_ok=True)

# Define sizes for each density
densities = {
    'drawable-mdpi': 48,
    'drawable-hdpi': 72,
    'drawable-xhdpi': 96,
    'drawable-xxhdpi': 144,
    'drawable-xxxhdpi': 192,
}

print("🎨 Generating notification icons...")

for density, size in densities.items():
    img = create_notification_icon(size)
    output_path = f"D:\\habitz\\android\\app\\src\\main\\res\\{density}\\ic_notification.png"
    img.save(output_path)
    print(f"✅ Created {density}: {size}x{size} -> {output_path}")

print("\n✅ All notification icons generated successfully!")
print("📱 You can now rebuild your app with: flutter clean && flutter pub get && flutter run")

