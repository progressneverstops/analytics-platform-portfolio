# A/B Experiments Framework

A generic A/B testing framework demonstrating experiment design, variant tracking, statistical comparison, and results analysis.

## Purpose

This project demonstrates:
- A/B experiment setup and management
- Variant assignment and tracking
- Statistical significance testing
- Results comparison and visualization
- Experiment reporting

## Architecture

```
Experiment Definition → Variant Assignment → Event Tracking → Statistical Analysis → Results
```

## Features

1. **Experiment Management**
   - Create experiments with variants
   - Define success metrics
   - Set experiment duration
   - Track experiment status

2. **Variant Assignment**
   - Random assignment
   - Consistent assignment (by user ID)
   - Traffic allocation
   - Exclusion rules

3. **Statistical Analysis**
   - Conversion rate comparison
   - Statistical significance (chi-square, t-test)
   - Confidence intervals
   - Effect size calculation

4. **Results Visualization**
   - Comparison charts
   - Statistical metrics display
   - Winner determination
   - Report generation

## Example Use Case

**Generic Feature Flag System** (not domain-specific):
- Test new features vs. control
- Measure conversion rates
- Determine statistical significance
- Make data-driven decisions

## Components

- `Experiment.swift` - Experiment definition
- `VariantAssigner.swift` - Variant assignment logic
- `StatisticalAnalyzer.swift` - Statistical tests
- `ExperimentResults.swift` - Results and visualization
