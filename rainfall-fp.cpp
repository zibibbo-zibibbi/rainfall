#include <iostream>
#include <algorithm>
#include <chrono>

using namespace std;
using namespace std::chrono;

class Slice {
private:
  double wall;
  double water;
  double air;

public:
  Slice(double wall = 0, double water = 0, double air = 0) {
    Slice::wall = wall;
    Slice::water = water;
    Slice::air = air;
  }

  bool LeakInto(Slice target) {
    if (air != 0)
      return false;
    double newWater = max(target.wall + target.water - wall, 0.0);
    air = water - newWater;
    water = newWater;
    return air > 0;
  }

  double Air() {
    return air;
  }
};


class World {
private:
  int width;
  double* raw;
  Slice* slices;
  double totalWater;

public:
  World(const double* heights, int count) {
    double worldHeight = heights[0];
    for (int i = 1; i < count; ++i) {
      if (heights[i] > worldHeight)
        worldHeight = heights[i];
    }
    width = count + 2;
    raw = new double[width * sizeof(Slice) / sizeof(double)];
    slices = reinterpret_cast<Slice*>(raw);
    totalWater = 0;

    Slice* cursor = slices;
    new(cursor) Slice(0, 0, worldHeight);

    for (int i = 0; i < count; ++i) {
      ++cursor;
      double w = worldHeight - heights[i];
      totalWater += w;
      new(cursor) Slice(heights[i], w);
    }

    ++cursor;
    new(cursor) Slice(0, 0, worldHeight);
  }

  ~World() {
    delete[] raw;
  }

  void Drain() {
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

  double Water() {
    return totalWater;
  }
};

int main() {
  const int count = 10000000;
  double* hs = new double[count];
  for (int i = 0; i < count; ++i) {
    hs[i] = 200.0 * (((double) rand()) / ((double) RAND_MAX));
  }

  auto start = system_clock::now().time_since_epoch();
  World sk(hs, count);
  auto lap = system_clock::now().time_since_epoch();
  sk.Drain();
  auto end = system_clock::now().time_since_epoch();
  auto creation = duration_cast<std::chrono::milliseconds>(lap - start);
  auto draining = duration_cast<std::chrono::milliseconds>(end - lap);
  auto total = duration_cast<std::chrono::milliseconds>(end - start);
  cout << sk.Water();
  cout << " creation: " << creation.count() <<
          " draining: " << draining.count() <<
          " tot: " << total.count() << endl;

  delete[] hs;

  return 0;
}
