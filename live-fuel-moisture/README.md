# Live Fuel Moisture Code

Live Fuel Moisture (LFM) refers to the amount of water contained in live vegetation, such as shrubs and trees. By measuring this moisture, fire managers can better predict how a fire will spread. High moisture levels typically mean that vegetation is less flammable, which can slow down or even stop the spread of a fire. Conversely, low moisture levels can lead to more intense and faster-moving fires.

## Script Explanations

- `lfm-01_wrangle.r` - ingest the 'raw' data and calculate desired metrics (including moisture content)
- `lfm-02_graph.r` – use the wrangled data to create desired graphs (especially the time series for the four key plant species that can be found on the [LKC website](https://lakretz.nrs.ucsb.edu/))

