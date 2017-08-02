using System;
using System.Linq;
using System.Diagnostics;


struct Slice {
  private int wall;
  private int water;
  private int air;

  public Slice(int wall = 0, int water = 0, int air = 0) {
    this.wall = wall;
    this.water = water;
    this.air = air;
  }

  public bool LeakInto(Slice target) {
    if (air != 0)
      return false;

    int newWater = Math.Max(target.wall + target.water - wall, 0);
    air = water - newWater;
    water = newWater;
    return air > 0;
  }

  public int Air() {
    return air;
  }
}


class World {
  private int width;
  private Slice[] slices;
  private int totalWater;

  public World(params int[] towerHeights) {
    totalWater = 0;

    width = towerHeights.Length + 2;
    int worldHeight = towerHeights.Max();
    slices = new Slice[width];

    int x = 0;
    slices[x++] = new Slice(air: worldHeight);
    foreach(int h in towerHeights) {
      int w = worldHeight - h;
      totalWater += w;
      slices[x++] = new Slice(wall: h, water:w );
    }
    slices[x] = new Slice(air: worldHeight);
  }

  public void Drain() {
    for (int x = 0; x < width - 1; ++x)
      if (!slices[x + 1].LeakInto(slices[x]))
        break;
      else
        totalWater -= slices[x + 1].Air();

    for (int x = width - 2; x >= 0; --x)
      if (!slices[x].LeakInto(slices[x + 1]))
        break;
      else
        totalWater -= slices[x].Air();
  }

  public int Water() {
    return totalWater;
  }
}


class Program {
  static void Main(string[] args) {
    Random r = new Random();
    int[] hs = new int[10000000];
    for(int i = 0; i < hs.Length; ++i)
      hs[i] = r.Next(200);

    double frequency = Stopwatch.Frequency;

    Stopwatch sw = Stopwatch.StartNew();
    long start = sw.ElapsedTicks;
    World sk = new World(hs);
    long lap = sw.ElapsedTicks;
    sk.Drain();
    int w = sk.Water();
    long end = sw.ElapsedTicks;
    long cre = lap - start;
    long sim = end - lap;
    long tot = end - start;
    Console.WriteLine("world creation: " + (cre / frequency) * 1000);
    Console.WriteLine("world draining: " + (sim / frequency) * 1000);
    Console.WriteLine("total: " + (tot / frequency) * 1000);
  }
}
