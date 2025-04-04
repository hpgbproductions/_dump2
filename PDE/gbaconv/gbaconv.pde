// gbaconv
// Converts an image into an array of palette indexing data. The result is compatible with the GBA's 1D VRAM format.
// Converted image
    // The image width and height must be a multiple of 8x8. All calculations will assume that this is true.
// Palette
    // The palette source is read row by row, from left to right.
    // The palette must start with the clearing color (to be treated transparent) in the top left.
    // A transparent pixel marks the end of the palette.

PImage Image;
PImage PaletteImage;
String ImagePath = "img.png";
String PalettePath = "pal.png";
ArrayList Palette = new ArrayList(16);

Boolean PixelSize8bpp = false;
int TransparentIndex = 0x00;
int AlphaThreshold = 128;

Boolean drawn = false;

// Output data
int[] PaletteIndexes;
StringBuilder OutStringBuilder = new StringBuilder(1000);

void setup()
{
  Image = loadImage(ImagePath);
  PaletteImage = loadImage(PalettePath);
  PaletteIndexes = new int[Image.width * Image.height];
  
  size(1, 1);
  windowResize(Image.width, Image.height);
  background(0);
}

void draw()
{
  if (drawn)
  {
    return;
  }
  drawn = true;
  
  // Read palette
  PaletteImage.loadPixels();
  for (int i = 0; i < PaletteImage.pixels.length; i++)
  {
    color c = PaletteImage.pixels[i];
    if (alpha(c) < AlphaThreshold)
    {
      break;
    }
    else
    {
      c |= 0xFF000000;        // Set opaque
      Palette.add(c);
    }
  }
  
  Image.loadPixels();
  loadPixels();
  
  int DataPosition = 0;
  
  // Loop for 8x8 tiles
  for (int yStart = 0; yStart < Image.height; yStart += 8)
  {
    for (int xStart = 0; xStart < Image.width; xStart += 8)
    {
      // BEGIN loop for a single tile
      for (int yTile = 0; yTile < 8; yTile++)
      {
        for (int xTile = 0; xTile < 8; xTile++)
        {
          // BEGIN single pixel
          int x = xStart + xTile;
          int y = yStart + yTile;
          color c = Image.pixels[y*Image.width + x];
          
          // Apply alpha threshold to treat the color as fully transparent or opaque
          if (alpha(c) < AlphaThreshold)
          {
            c &= 0x00FFFFFF;
          }
          else
          {
            c |= 0xFF000000;
          }
          
          if (alpha(c) == 0)
          {
            PaletteIndexes[DataPosition] = TransparentIndex;
          }
          else
          {
            for (int p = 0; p < Palette.size(); p++)
            {
              Boolean MatchingColorFound = false;
              
              if (c == (color)Palette.get(p))
              {
                PaletteIndexes[DataPosition] = p;
                MatchingColorFound = true;
                break;
              }
              
              // If no color was found, treat as transparent color index
              if (!MatchingColorFound)
              {
                PaletteIndexes[DataPosition] = TransparentIndex;
              }
            }
          }
          
          // Area to make visualizations for debugging
          //pixels[y*width + x] = 0xFF000000 | PaletteIndexes[DataPosition];
          pixels[y*width + x] = 0xFF000000 | DataPosition;
          
          // END single pixel
          DataPosition++;
        }
      }
      // END loop for a single tile
    }
  }
  
  // Convert tile arrangement to text
  for (int i = 0; i < PaletteIndexes.length; i++)
  {
    if (PixelSize8bpp)
    {
      OutStringBuilder.append("0x" + hex(PaletteIndexes[i], 2));
      
      if (i != Image.pixels.length - 1)
      {
        OutStringBuilder.append(", ");
      }
    }
    else // 4bpp (for some reason, to get ABCDEFGH, you must write 0xBA 0xDC 0xFE 0xHG
    {
      if (i % 2 == 0)
      {
        OutStringBuilder.append("0x" + hex(PaletteIndexes[i+1], 1));
      }
      else
      {
        OutStringBuilder.append(hex(PaletteIndexes[i-1], 1));
        if (i != Image.pixels.length - 1)
        {
          OutStringBuilder.append(", ");
        }
      }
    }
    
    if (i % 8 == 7)
    {
      OutStringBuilder.append("\n\t");
    }
  }
  
  // Apply visualization
  updatePixels();
  print(OutStringBuilder);
}
