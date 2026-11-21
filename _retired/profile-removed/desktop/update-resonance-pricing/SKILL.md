---
name: update-resonance-pricing
description: Fetch the latest OpenAI model pricing from the published markdown document and update the pricing/token cost configuration in appsettings.json. Use this skill whenever the user asks to update AI pricing, sync token costs, refresh model rates, or update appsettings.json with the latest OpenAI pricing for the Resonance application.
---

# OpenAI Pricing Updater for Resonance

Updates `appsettings.json` with the latest OpenAI model pricing for token cost calculation.

## Steps

### 1. Fetch Latest Pricing

Fetch the official OpenAI pricing page in markdown format:
```
https://developers.openai.com/api/docs/pricing.md
```

Extract the per-model pricing for:
- Input tokens (cost per million tokens)
- Output tokens (cost per million tokens)
- Cache write tokens (if applicable)
- Cache read tokens (if applicable)

### 2. Locate appsettings.json

Find the appsettings.json file in the Resonance.UI project (the API's copy is handled in step 6). Look for the section called `ModelPricing`:
```json
"ModelPricing": {
    "openai": {
      "gpt-5.4":                        
      { 
        "inputPerMillionTokens": 2.50,   
        "outputPerMillionTokens": 15.00,
        "cachedInputPerMillionTokens": 0.25    
      },
    }
  },
```

### 3. Update the Values

- Remove ALL existing values in the JSON file
- Replace with the new data from the file
- Match each model name exactly to the official OpenAI model ID
- Update input/output/cached costs per 1M tokens
- Preserve any existing structure and other settings

### 4. Confirm with User

Before writing, show the user a summary table of:
- Model name
- Old input cost → New input cost
- Old output cost → New output cost

Ask for confirmation before saving.

### 5. Write Changes

Apply the changes to appsettings.json and confirm success.

### 6. Update the API's copy

`source/Resonance.Api/appsettings.json` carries a copy of the desktop's whole `ModelPricing` and
`ModelCapabilities` sections, and the same `AiFeatures:Features:AskResonance` default (#1150). Write
the same `ModelPricing` section there as was written to the desktop's file, and copy across any
change to `ModelCapabilities` or to the AskResonance default. Leave the API file's other sections
alone.

Then run `dotnet test source/Resonance.Api.Tests --filter "FullyQualifiedName~ShippedAiConfigurationTests"`.
It fails if the two files disagree on the Ask default model, or on either table.
