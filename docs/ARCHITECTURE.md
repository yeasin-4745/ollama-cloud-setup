# Architecture Overview

## Google Cloud Shell Storage Limits

Google Cloud Shell provides two primary storage locations with distinct characteristics:

| **Path**       | **Type**       | **Size**       | **Persistence**               | **Use Case**                          |
|----------------|----------------|----------------|-------------------------------|---------------------------------------|
| `/home`        | Persistent     | 5GB            | Survives sessions             | Config files, small scripts           |
| `/tmp`         | Ephemeral      | 100GB+         | **Cleared after inactivity** | Large models, temporary files         |

## Why Store Models in `/tmp`?

1. **Space Constraints**:
   - `/home` is limited to **5GB**, which is insufficient for most Ollama models (e.g., `qwen2.5:1.5b` requires ~3GB).
   - `/tmp` provides **100GB+**, enough for multiple models.

2. **Performance**:
   - `/tmp` is often mounted on a **faster filesystem** (e.g., RAM disk or high-speed SSD).

3. **Cloud Shell Behavior**:
   - Files in `/tmp` persist **during an active session** but are cleared after ~30 minutes of inactivity.
   - Models must be re-pulled if the session expires, but this is a trade-off for space.

## Workflow

```
Cloud Shell Session
├── /home (5GB)
│   ├── .config/ollama/       (Config files)
│   └── .bashrc               (Environment variables)
└── /tmp (100GB+)
    └── ollama_models/        (Downloaded models)
```

## Key Environment Variables

| **Variable**         | **Purpose**                          | **Recommended Value**       |
|----------------------|--------------------------------------|-----------------------------|
| `OLLAMA_MODELS`      | Model storage directory             | `/tmp/ollama_models`        |
| `OLLAMA_HOST`        | Server host (for remote access)     | `0.0.0.0`                   |

## Notes
- **Ephemeral Nature**: Always assume `/tmp` is temporary. Use `scripts/start.sh` to re-pull models on session restart.
- **Avoid `/home` for Models**: Hardcoding `OLLAMA_MODELS=/home/...` will fail with `ENOSPC` errors.
