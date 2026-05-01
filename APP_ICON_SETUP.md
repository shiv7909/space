# App Icon Setup Guide

## Current Status
✅ `flutter_launcher_icons` package has been added to `pubspec.yaml`
✅ Configuration is ready
⚠️ Need to create PNG images from vvv.svg

## Steps to Generate App Icons

### Step 1: Convert SVG to PNG

You need to convert `assets/Svg/vvv.svg` to PNG format. You can use:

**Option A: Online Tool (Easiest)**
1. Go to https://cloudconvert.com/svg-to-png or https://svgtopng.com/
2. Upload `assets/Svg/vvv.svg`
3. Set size to 1024x1024 pixels (high resolution)
4. Download the PNG

**Option B: Using Inkscape (Free Desktop App)**
```bash
inkscape assets/Svg/vvv.svg -o assets/images/app_icon.png -w 1024 -h 1024
```

**Option C: Using ImageMagick**
```bash
magick convert -background white -density 1024 assets/Svg/vvv.svg -resize 1024x1024 assets/images/app_icon.png
```

### Step 2: Create Required PNG Files

After converting, create these two files:
1. **Main Icon**: `assets/images/app_icon.png` (1024x1024)
   - This is the full vvv logo on white background

2. **Foreground Icon** (for Android Adaptive Icons): `assets/images/app_icon_foreground.png` (1024x1024)
   - This should be the vvv logo centered with transparent padding around it
   - Leave about 20% transparent margin on all sides

### Step 3: Run Flutter Commands

Once you have the PNG files in place, run:

```bash
# Install dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Step 4: Verify Icons

After rebuilding:
- **Android**: Check the app drawer icon
- **iOS**: Check the home screen icon
- The splash screen will show vvv.svg (already configured)

## Configuration Details

The `pubspec.yaml` is configured with:
- ✅ Android support enabled
- ✅ iOS support enabled  
- ✅ White background color
- ✅ Adaptive icons for Android (with separate foreground/background)

## Quick Manual Method

If you want to skip automatic generation, manually create PNG versions at these sizes:
- 48x48 (mdpi)
- 72x72 (hdpi)
- 96x96 (xhdpi)
- 144x144 (xxhdpi)
- 192x192 (xxxhdpi)

And place them in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

## Current vvv.svg Details
- Simple red "V" logo
- Clean and minimal design
- Perfect for app icon
- Red color (#FE3636) on white background

