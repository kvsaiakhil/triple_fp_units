# Triple-FP Block Diagrams

This document collects the top-level block diagrams for the four implemented units in one place.

The diagrams are also mirrored in [README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/README.md).

## `TripleAddPipe_l4_f64`

```mermaid
flowchart LR
  A["65-bit recFN shell inputs"] --> B["Wrapper Input Register"]
  B --> C["TripleAddRecFNToRaw<br/>decode<br/>align<br/>accumulate<br/>normalize"]
  C --> D["Inner Stage-0 Register<br/>raw bundle + rm"]
  D --> E["RoundRawFNToRecFN_e11_s53"]
  E --> F["Inner Stage-1 Register"]
  F --> G["Wrapper Output Register"]
```

## `TripleAddPipe_l4_f32`

```mermaid
flowchart LR
  A["65-bit shell inputs"] --> B["Wrapper Input Register"]
  B --> C["Low 33-bit extract"]
  C --> D["TripleAddRecFNToRaw<br/>decode<br/>align<br/>accumulate<br/>normalize"]
  D --> E["Inner Stage-0 Register<br/>raw bundle + rm"]
  E --> F["RoundRawFNToRecFN_e8_s24"]
  F --> G["Inner Stage-1 Register"]
  G --> H["Wrapper Output Register<br/>33-bit result repacked into 65-bit shell"]
```

## `TripleMulPipe_l4_f64`

```mermaid
flowchart LR
  A["65-bit recFN shell inputs"] --> B["Wrapper Input Register"]
  B --> C["TripleMulRecFNToRaw<br/>decode<br/>triple product<br/>normalize<br/>exp clamp"]
  C --> D["Inner Stage-0 Register<br/>raw bundle + rm"]
  D --> E["RoundRawFNToRecFN_e11_s53"]
  E --> F["Inner Stage-1 Register"]
  F --> G["Wrapper Output Register"]
```

## `TripleMulPipe_l4_f32`

```mermaid
flowchart LR
  A["65-bit shell inputs"] --> B["Wrapper Input Register"]
  B --> C["Low 33-bit extract"]
  C --> D["TripleMulRecFNToRaw<br/>decode<br/>triple product<br/>normalize<br/>exp clamp"]
  D --> E["Inner Stage-0 Register<br/>raw bundle + rm"]
  E --> F["RoundRawFNToRecFN_e8_s24"]
  F --> G["Inner Stage-1 Register"]
  G --> H["Wrapper Output Register<br/>33-bit result repacked into 65-bit shell"]
```

## Reading Notes

- `f64` units operate directly on 65-bit recFN inputs and outputs.
- `f32` units use the BOOM-style 65-bit shell externally, but the active datapath is the low 33 bits.
- All four units preserve the same visible 4-stage interface shape as the original FMA wrappers.
