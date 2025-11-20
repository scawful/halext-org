# AI Model Selection Guide

## Quick Start

After configuring your OpenAI or Gemini API keys in the admin panel, you can select AI models in the iOS app:

1. Open **Settings** → **AI Settings**
2. Tap **AI Model**
3. Browse and select from available models
4. Models are automatically filtered based on your configured API keys

## Understanding Model Tiers

Models are categorized into three tiers, indicated by colored badges:

### 🟢 Lightweight (Green)
**Best for**: Testing, development, simple tasks, high-volume requests

| Model | Provider | Cost | Context | Use Cases |
|-------|----------|------|---------|-----------|
| gpt-3.5-turbo | OpenAI | $0.50/$1.50 | 16K | Quick responses, simple Q&A, prototyping |
| gemini-1.5-flash | Google | $0.075/$0.30 | 1M | Ultra-fast, huge context, batch processing |

**Recommendation**: Use `gemini-1.5-flash` for testing due to lowest cost and massive context window.

### 🔵 Standard (Blue)
**Best for**: Production apps, balanced quality/cost, general use

| Model | Provider | Cost | Context | Use Cases |
|-------|----------|------|---------|-----------|
| gpt-4o-mini | OpenAI | $0.15/$0.60 | 128K | Production chatbots, content generation, vision tasks |
| gemini-1.5-pro | Google | $1.25/$5.00 | 2M | Document analysis, complex reasoning, long conversations |

**Recommendation**: Use `gpt-4o-mini` for most production apps (great price/performance + vision).

### 🟣 Premium (Purple)
**Best for**: Complex reasoning, critical tasks, latest capabilities

| Model | Provider | Cost | Context | Use Cases |
|-------|----------|------|---------|-----------|
| gpt-4o | OpenAI | $5.00/$15.00 | 128K | Advanced analysis, creative writing, multimodal tasks |
| gpt-4-turbo | OpenAI | $10.00/$30.00 | 128K | Comprehensive tasks requiring high intelligence |
| gemini-exp-1206 | Google | FREE* | 2M | Cutting-edge features (experimental) |

*Free during preview period

**Recommendation**: Use `gpt-4o` when quality matters more than cost.

## Model Capabilities

### Vision Support 👁️
Models with vision can analyze images:
- All `gpt-4o` variants
- All `gemini-1.5` and `gemini-2.0` models

**Use cases**: Image description, OCR, visual Q&A, chart analysis

### Function Calling ⚙️
Models that can call external functions/tools:
- All GPT-4 and GPT-3.5 models
- All Gemini models

**Use cases**: Database queries, API calls, structured data extraction

## Cost Examples

Based on typical usage patterns:

### Chat Application (1000 messages/day)
Assuming avg 500 input + 300 output tokens per message:

| Model | Daily Cost | Monthly Cost |
|-------|-----------|--------------|
| gpt-3.5-turbo | $1.20 | $36 |
| gpt-4o-mini | $0.63 | $19 |
| gemini-1.5-flash | $0.13 | $4 |
| gpt-4o | $6.00 | $180 |

### Document Summarization (100 docs/day)
Assuming 5000 input + 500 output tokens per doc:

| Model | Daily Cost | Monthly Cost |
|-------|-----------|--------------|
| gpt-3.5-turbo | $3.25 | $98 |
| gpt-4o-mini | $1.05 | $32 |
| gemini-1.5-flash | $0.53 | $16 |
| gemini-1.5-pro | $6.88 | $206 |

## Context Window Guide

Context window = how much text the model can "remember" at once.

| Window Size | Real-World Equivalent |
|-------------|----------------------|
| 8K tokens | ~6 pages of text |
| 16K tokens | ~12 pages of text |
| 32K tokens | ~24 pages of text |
| 128K tokens | ~96 pages / small book |
| 1M tokens | ~750 pages / large novel |
| 2M tokens | ~1500 pages / encyclopedia |

**Tip**: 1 token ≈ 0.75 words in English

## Choosing the Right Model

### For Chat/Conversation
- **Budget**: `gemini-1.5-flash`
- **Balanced**: `gpt-4o-mini`
- **Premium**: `gpt-4o`

### For Document Analysis
- **Short docs (<10 pages)**: `gpt-4o-mini`
- **Long docs (10-100 pages)**: `gemini-1.5-flash`
- **Very long docs (100+ pages)**: `gemini-1.5-pro`

### For Vision Tasks
- **Budget**: `gpt-4o-mini`
- **Premium**: `gpt-4o`
- **Experimental**: `gemini-2.0-flash-exp` (free!)

### For Code Generation
- **Quick scripts**: `gpt-3.5-turbo`
- **Production code**: `gpt-4o-mini` or `gpt-4o`
- **Code review**: `gemini-1.5-pro` (huge context helps)

### For Creative Writing
- **Drafts**: `gpt-3.5-turbo`
- **Polished content**: `gpt-4o`
- **Long-form**: `gemini-1.5-pro` (2M context)

## Special Models

### Free During Preview
- `gemini-2.0-flash-exp`: Next-gen features, free while in preview
- `gemini-exp-1206`: Experimental model with advanced capabilities

These are great for testing new features without cost, but may have:
- Rate limits
- Unstable responses
- Changes without notice
- No SLA guarantees

### Legacy Models
- `gpt-4`: Original GPT-4, now outperformed by `gpt-4o` at lower cost
- `gemini-1.0-pro`: Superseded by `gemini-1.5` models

## Model Metadata in iOS App

When browsing models in the app, you'll see:

```
gpt-4o-mini                    [Standard]
Affordable and intelligent small model
📄 128K tokens   💵 $0.15/$0.60 per 1M
👁️ Vision   ⚙️ Functions
```

Breaking this down:
- **Name**: Model identifier
- **Badge**: Tier (Lightweight/Standard/Premium)
- **Description**: Best use cases
- **📄 Context**: Token capacity
- **💵 Cost**: Input/Output per 1M tokens
- **👁️ Vision**: Supports image analysis
- **⚙️ Functions**: Can call external tools

## Switching Models

You can change models anytime:

1. Go to **Settings** → **AI Settings**
2. Tap **AI Model**
3. Select a new model
4. The app will use this model for all AI features

To reset to default:
1. In AI Settings, tap **Reset to Default**
2. The app will auto-select the best available model

## Rate Limits

Be aware of provider rate limits:

### OpenAI (Tier 1)
- GPT-3.5: 3,500 requests/min
- GPT-4: 500 requests/min
- GPT-4o: 500 requests/min

### Gemini
- Gemini 1.5 Flash: 1000 requests/min (free tier: 15/min)
- Gemini 1.5 Pro: 1000 requests/min (free tier: 2/min)

**Tip**: Use multiple models to distribute load and avoid hitting limits.

## Troubleshooting

### "No Models Available"
- Check admin panel: Are API keys configured?
- Tap refresh button in model picker
- Restart the app

### "Model not responding"
- Check rate limits (may be temporarily throttled)
- Try a different model
- Check provider status pages

### "Unexpected responses"
- Experimental models may behave unpredictably
- Switch to stable models for production
- Report issues to model provider

## Best Practices

1. **Start with lightweight models** during development
2. **Test with production models** before deploying
3. **Monitor costs** in provider dashboards
4. **Use appropriate context windows** (don't waste tokens on small models with huge prompts)
5. **Cache responses** when possible to reduce API calls
6. **Implement fallbacks** to alternate models if primary fails
7. **Set budgets** in provider dashboards to avoid surprises

## Provider Comparison

| Feature | OpenAI | Google Gemini |
|---------|--------|---------------|
| Cheapest model | gpt-3.5-turbo ($0.50) | gemini-1.5-flash ($0.075) |
| Best value | gpt-4o-mini ($0.15) | gemini-1.5-flash ($0.075) |
| Largest context | 128K tokens | 2M tokens |
| Vision support | gpt-4o, gpt-4o-mini | All 1.5+ models |
| Free options | None (trial credits) | Experimental models |
| API maturity | Very stable | Rapidly evolving |

## Cost Optimization Tips

1. **Use streaming** for long responses (better UX, same cost)
2. **Trim context** to only essential information
3. **Batch requests** when possible
4. **Cache common queries**
5. **Use cheaper models** for initial filtering, expensive for final processing
6. **Set max tokens** to avoid runaway costs
7. **Monitor usage** in provider dashboards

## Getting Help

- **Provider docs**: [OpenAI](https://platform.openai.com/docs) | [Gemini](https://ai.google.dev)
- **Pricing**: [OpenAI Pricing](https://openai.com/pricing) | [Gemini Pricing](https://ai.google.dev/pricing)
- **Status**: [OpenAI Status](https://status.openai.com) | [Google Cloud Status](https://status.cloud.google.com)

## Summary

- **Testing**: Use `gemini-1.5-flash` (ultra cheap)
- **Production**: Use `gpt-4o-mini` (best balance)
- **Premium**: Use `gpt-4o` (highest quality)
- **Long documents**: Use `gemini-1.5-pro` (2M context)
- **Experimental**: Try `gemini-2.0-flash-exp` (free!)

The iOS app makes it easy to switch between models. Start conservative, monitor costs, and upgrade as needed.
