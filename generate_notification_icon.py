#!/usr/bin/env python3
"""
Generate a proper notification icon with bold "S" in white on black background
"""
from PIL import Image, ImageDraw, ImageFont
import os

# Create image
img = Image.new('RGBA', (192, 192), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw black circle background
circle_box = [16, 16, 176, 176]
draw.ellipse(circle_box, fill=(0, 0, 0, 255))

# Try to use a bold font, fall back to default
try:
    # Try common bold fonts
    font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", 140)
except:
    try:
        font = ImageFont.truetype("C:\\Windows\\Fonts\\ArialBD.ttf", 140)
    except:
        font = ImageFont.load_default()

# Draw white "S" in center
text = "S"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]

x = (192 - text_width) // 2
y = (192 - text_height) // 2 - 10

draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

# Create output directory if needed
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-mdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-hdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxhdpi", exist_ok=True)
os.makedirs("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxxhdpi", exist_ok=True)

# Save for mdpi (96x96)
img_mdpi = img.resize((96, 96), Image.Resampling.LANCZOS)
img_mdpi.save("D:\\habitz\\android\\app\\src\\main\\res\\drawable-mdpi\\ic_notification.png")
print("✅ Saved mdpi (96x96)")

# Save for hdpi (144x144)
img_hdpi = img.resize((144, 144), Image.Resampling.LANCZOS)
img_hdpi.save("D:\\habitz\\android\\app\\src\\main\\res\\drawable-hdpi\\ic_notification.png")
print("✅ Saved hdpi (144x144)")

# Save for xhdpi (192x192)
img.save("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xhdpi\\ic_notification.png")
print("✅ Saved xhdpi (192x192)")

# Save for xxhdpi (288x288)
img_xxhdpi = img.resize((288, 288), Image.Resampling.LANCZOS)
img_xxhdpi.save("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxhdpi\\ic_notification.png")
print("✅ Saved xxhdpi (288x288)")

# Save for xxxhdpi (384x384)
img_xxxhdpi = img.resize((384, 384), Image.Resampling.LANCZOS)
img_xxxhdpi.save("D:\\habitz\\android\\app\\src\\main\\res\\drawable-xxxhdpi\\ic_notification.png")
print("✅ Saved xxxhdpi (384x384)")

print("\n✅ All notification icons generated successfully!")

