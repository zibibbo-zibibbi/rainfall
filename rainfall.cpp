#include <iostream>
#include <algorithm>
#include <chrono>

using namespace std;
using namespace std::chrono;

class Slice {
private:
  int wall;
  int water;
  int air;

public:
  Slice(int wall = 0, int water = 0, int air = 0) {
    Slice::wall = wall;
    Slice::water = water;
    Slice::air = air;
  }

  bool LeakInto(Slice target) {
    if (air != 0)
      return false;
    int newWater = max(target.wall + target.water - wall, 0);
    air = water - newWater;
    water = newWater;
    return air > 0;
  }

  int Air() {
    return air;
  }
};


class World {
private:
  int width;
  int* raw;
  Slice* slices;
  int totalWater;

public:
  World(const int* heights, int count) {
    int worldHeight = heights[0];
    for (int i = 1; i < count; ++i) {
      if (heights[i] > worldHeight)
        worldHeight = heights[i];
    }
    width = count + 2;
    raw = new int[width * sizeof(Slice) / sizeof(int)];
    slices = reinterpret_cast<Slice*>(raw);
    totalWater = 0;

    Slice* cursor = slices;
    new(cursor) Slice(0, 0, worldHeight);

    for (int i = 0; i < count; ++i) {
      ++cursor;
      int w = worldHeight - heights[i];
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

  int Water() {
    return totalWater;
  }
};

int main() {
  const int count = 10000000;
  int* hs = new int[count];
  for (int i = 0; i < count; ++i) {
    hs[i] = rand() % 200;
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
