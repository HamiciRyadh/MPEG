final int K = 32;
final int N = 16;
final int NBRE_IMAGES = 90;
final float ERROR_MARGIN = 3*16*N*N;

final int I_FRAME = 10;

PImage f0, f1;
int w, h, loc, y, x;
ILum il, il2;
        
ILum[][] fp0 = new ILum[1088][1920];
ILum[][] fp1 = new ILum[1088][1920];

ArrayList<Block> residus = new ArrayList<Block>();
ArrayList<Block> oldResidus = null;
ArrayList<ChangeVect> vecteurs = new ArrayList<ChangeVect>();
ArrayList<ChangeVect> oldVecteurs = null;

int index = 0;

void setup() {
  size(1920, 1088);
  println("Image : " + 0 +", I.");
  f0 = loadImage(nomImage(0));
  w=f0.width;
  h=f0.height;
  loadPixels();
  f0.loadPixels();
  fp0 = remplirFp(f0);
  fp1 = fp0;
  
  for (y = 0; y < h; y++) {
    for (x = 0; x < w; x++) {
      loc = x +y*w;
      il = fp0[y][x];
      pixels[loc] = color(il.y + 1.140*il.v, il.y - 0.395*il.u - 0.581*il.v, il.y + 2.032*il.u);
    }
  }
}

void draw() {
  if (index <= NBRE_IMAGES-1) {
    index++;
    f1 = loadImage(nomImage(index));
    f1.loadPixels();
    
    if (index%I_FRAME == 0) {
      println("\nImage : " + index+", I.");
      fp0 = fp1;
      index++;
      
      for (y = 0; y < h; y++) {
        for (x = 0; x < w; x++) {
          loc = x +y*w;
          il = fp0[y][x];
          pixels[loc] = color(il.y + 1.140*il.v, il.y - 0.395*il.u - 0.581*il.v, il.y + 2.032*il.u);
        }
      }
      
      oldResidus = null;
      oldVecteurs = null;
      
      f1 = loadImage(nomImage(index));
      f1.loadPixels();
    }
    
    println("\nImage : " + index +", P.");
    fp1 = remplirFp(f1);
    genererOut();
    
    println("Nombres de blocks residus " + residus.size());
    println("Nombres de vecteurs de deplacements " + vecteurs.size());
    
    //Reinitialiser les blocs modifies lors de la precedente image P a leur ancienne valeur (celle de I)
    if (oldVecteurs != null) {
      for (ChangeVect cv : vecteurs) {
        for (y = 0; y < N; y++) {
          for (x = 0; x < N; x++) {
            loc = cv.xp+x + (cv.yp+y)*w;
            il = fp0[cv.yi+y][cv.xi+x];
            pixels[loc] = color(il.y + 1.140*il.v, il.y - 0.395*il.u - 0.581*il.v, il.y + 2.032*il.u);
          }
        }
      }
      oldVecteurs.clear();
    }
    
    //Reinitialiser les blocs modifies lors de la precedente image P a leur ancienne valeur (celle de I)
    if (oldResidus != null) {
      for (Block b : oldResidus) {
        for (y = 0; y < N; y++ ) {
          for (x = 0; x < N; x++ ) {
             loc = b.posX+x + (b.posY+y)*w;
             il = fp0[b.posY+y][b.posX+x];
             pixels[loc] = color(il.y + 1.140*il.v, il.y - 0.395*il.u - 0.581*il.v, il.y + 2.032*il.u);
          }
        }
      }
      oldResidus.clear();
    }
    
    //Vecteurs de deplacements
    oldVecteurs = vecteurs;
    for (ChangeVect cv : vecteurs) {
      for (y = 0; y < N; y++) {
        for (x = 0; x < N; x++) {
          loc = cv.xp+x + (cv.yp+y)*w;
          il = fp0[cv.yi+y][cv.xi+x];
          pixels[loc] = color(il.y + 1.140*il.v, il.y - 0.395*il.u - 0.581*il.v, il.y + 2.032*il.u);
        }
      }
    }
    
    //Blocks residus
    oldResidus = residus;
    for (Block b : residus) {
      for (y = 0; y < N; y++ ) {
        for (x = 0; x < N; x++ ) {
           loc = b.posX+x + (b.posY+y)*w;
           il = fp0[b.y+y][b.x+x];
           il2 = b.residu[y][x];
           pixels[loc] = color((il.y - il2.y) + 1.140*(il.v - il2.v), (il.y - il2.y) - 0.395*(il.u - il2.u) - 0.581*(il.v - il2.v), (il.y - il2.y) + 2.032*(il.u - il2.u));
        }
      }
    }
    updatePixels();
    saveFrame("Databis/"+nomImage(index));
  }
}

String nomImage(int idx) {
  String val = "image";
  if (idx < 10) val = val + "00" + idx + ".png";
  else if (idx < 100) val = val + "0" + idx + ".png";
  else val = val + idx + ".png";
  
  return val;
}


ILum[][] remplirFp(PImage img) {
  ILum[][] value = new ILum[1088][1920];
  color c;
  float r,g,b;
  for (x = 0; x < w; x++ ) {
    for (y = 0; y < h; y++ ) {
     loc = x + y*w;
     c = color(img.pixels[loc]);
     il = new ILum();
      r = red(c);
      g = green(c);
      b = blue(c);
     il.y = 0.299*r + 0.587*g + 0.114*b;
     il.u =  0.492*(b - il.y);
     il.v = 0.877*(r - il.y);
     value[y][x] = il;
    }
  }
  
  for (x = 0; x < 1920; x++) {
    for (y = 1080; y < 1080+8; y++) {
      il = new ILum();
      il.y = 0;
      il.u = 0;
      il.v = 0;
      value[y][x] = il;
    }
  }

  return value;
}

void genererOut() {
  residus = new ArrayList<Block>();
  vecteurs = new ArrayList<ChangeVect>();
  Block b;
  int i = 0, j;
  while (i < 1088) {
    j = 0;
    while (j < 1920) {
      //b = rechercheBlocSeq(fp0, fp1, i, j, N, K);

      b = mse(fp0, fp1, i, j, i, j, N);
      b.posX = j;
      b.posY = i;
      b = rechercheBlocDicho(fp0, fp1, N, K, b);
   
      if (b.error > ERROR_MARGIN) {     
        b.posX = j;
        b.posY = i;
        residus.add(b);
      } else {
        if (b.x != b.posX || b.y != b.posY) {
          vecteurs.add(new ChangeVect(b.y, b.x, b.posY, b.posX));
        }
      }
      
      j += N;
    }
    i += N;
  }
}

Block mse(ILum[][] mat1, ILum[][] mat2, int startY, int startX, int y, int x, int n) {
  float mse = 0, diff;
  int i, j;
  Block b = new Block();
  b.residu = new ILum[n][n];
  
  for (i = startY; i < startY+n; i++) {
    for (j = startX; j < startX+n; j++) {
      b.residu[i-startY][j-startX] = new ILum();
      b.residu[i-startY][j-startX].y = mat1[i][j].y - mat2[y+i-startY][x+j-startX].y;
      b.residu[i-startY][j-startX].u = mat1[i][j].u - mat2[y+i-startY][x+j-startX].u;
      b.residu[i-startY][j-startX].v = mat1[i][j].v - mat2[y+i-startY][x+j-startX].v;
      diff = b.residu[i-startY][j-startX].y;
      mse = mse + diff*diff;
      diff = b.residu[i-startY][j-startX].u;
      mse = mse + diff*diff;
      diff = b.residu[i-startY][j-startX].v;
      mse = mse + diff*diff;
    }
  }
  b.error = mse;
  b.y = startY;
  b.x = startX;
  
  return b;
}


Block rechercheBlocSeq(ILum[][] mat1, ILum[][] mat2, int y, int x, int n, int k) {
  Block b1 = new Block(), b2;
  int i, j;
    
  if (y >= 0 && y+n <= mat1.length && x >= 0 && x+n <= mat1[0].length) {
    b1 = mse(mat1, mat2, y, x, y, x, n);
    b1.x = x;
    b1.y = y;
    if (b1.error <= ERROR_MARGIN) return b1;
  }
    
  for (i = y-k; i < y+k; i++) {
    for (j = x-k; j < x+k; j++) {
      if (i >= 0 && i+n <= mat1.length && j >= 0 && j+n <= mat1[0].length) {
        b2 = mse(mat1, mat2, i, j, y, x, n);
        b2.x = x;
        b2.y = y;
        if (b1.error > b2.error) {
          b1 = b2;
        }
        if (b2.error <= ERROR_MARGIN) return b2;
      }
    }
  }
  
  return b1;
}


Block rechercheBlocDicho(ILum[][] mat1, ILum[][] mat2, int n, int k, Block origin) {
  if (origin.error <= ERROR_MARGIN) return origin;
  if (k < 16) {
    return origin;
  }
  
  Block b1, b2;
  b1 = origin;
  
  int i, j;
  
  for (i = origin.y-k; i <= origin.y+k; i += n) {
    for (j = origin.x-k; j <= origin.x+k; j += n) {
      if (i >= 0 && i+n <= mat1.length && j >= 0 && j+n <= mat1[0].length) {
        b2 = mse(mat1, mat2, i, j, origin.posY, origin.posX, n);
        if (b1.error > b2.error) {
          b1 = b2;
        }
      }
    }
  }
  
  b1.posX = origin.posX;
  b1.posY = origin.posY;
  if (b1 == origin) return origin;
  
  return rechercheBlocDicho(fp0, fp1, n, k/2, b1);
}



ILum[][] fusionner(ILum[][] mat) {
  ILum[][] result = new ILum[mat.length/2][mat[0].length/2];
  
  int i = 0, j;
  while (i < mat.length) {
    j = 0;
    while (j < mat[i].length) {
      result[i/2][j/2] = new ILum();
      result[i/2][j/2].y = (mat[i][j].y + mat[i+1][j].y + mat[i][j+1].y + mat[i+1][j+1].y)/4;
      result[i/2][j/2].u = (mat[i][j].u + mat[i+1][j].u + mat[i][j+1].u + mat[i+1][j+1].u)/4;
      result[i/2][j/2].v = (mat[i][j].v + mat[i+1][j].v + mat[i][j+1].v + mat[i+1][j+1].v)/4;
      j += 2;
    }
    i += 2;
  }
  
  return result;
}
