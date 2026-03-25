# Flashbook Architecture Diagrams (Mermaid)

## Component Diagram

```mermaid
flowchart TB
    subgraph Client[Client Layer]
        Flutter[Flutter App]
        Providers[Provider State Layer]
        LocalStore[SharedPreferences + In-memory Cache]
    end

    subgraph API[API Edge]
        APIGW[API Gateway /Prod]
        COG[Cognito Authorizer]
    end

    subgraph Compute[Compute Layer]
        LAuth[Lambda: auth.py]
        LBooks[Lambda: books.py]
        LExtract[Lambda: extract_text.py]
        LSummary[Lambda: generate_summary.py]
        LImage[Lambda: generate_image.py]
        LNotes[Lambda: notes.py]
        LHealth[Lambda: health.py]
    end

    subgraph Data[Data Layer]
        DDBSlides[(DynamoDB: flashbook-slides)]
        DDBNotes[(DynamoDB: flashbook-notes)]
        DDBBooks[(DynamoDB: flashbook-user-books)]
        S3PDF[(S3: PDF Bucket)]
        S3IMG[(S3: Images Bucket)]
    end

    subgraph External[External AI]
        GeminiText[Gemini Text Model]
        GeminiImage[Gemini Image Model]
        Pollinations[Pollinations Fallback]
    end

    Flutter --> Providers
    Providers --> APIGW
    Providers --> LocalStore

    APIGW --> COG
    APIGW --> LAuth
    APIGW --> LBooks
    APIGW --> LExtract
    APIGW --> LSummary
    APIGW --> LImage
    APIGW --> LNotes
    APIGW --> LHealth

    LAuth --> COG
    LBooks --> DDBBooks
    LBooks --> S3PDF
    LExtract --> S3PDF
    LSummary --> DDBSlides
    LSummary --> GeminiText
    LImage --> GeminiImage
    LImage --> S3IMG
    LImage --> Pollinations
    LNotes --> DDBNotes
```

## Sequence Diagram: Auth + Session Restore

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant App as Flutter App
    participant APIGW as API Gateway
    participant Auth as Lambda auth.py
    participant Cognito as Cognito

    U->>App: Open app
    App->>APIGW: GET /health
    APIGW->>App: 200 healthy

    App->>App: Load stored refresh token
    App->>APIGW: POST /auth/refresh
    APIGW->>Auth: Invoke
    Auth->>Cognito: initiate_auth(REFRESH_TOKEN_AUTH)
    Cognito-->>Auth: New id/access token
    Auth-->>APIGW: Token payload
    APIGW-->>App: 200 tokens

    alt No valid refresh token
        App->>APIGW: POST /auth/login
        APIGW->>Auth: Invoke
        Auth->>Cognito: USER_PASSWORD_AUTH
        Cognito-->>Auth: id/access/refresh tokens
        Auth-->>App: Auth success
    end
```

## Sequence Diagram: PDF Upload and Initial Processing

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant App as Flutter App
    participant APIGW as API Gateway
    participant Books as Lambda books.py
    participant Extract as Lambda extract_text.py
    participant Summary as Lambda generate_summary.py
    participant S3 as S3 PDF Bucket
    participant DDB as DynamoDB user-books/slides
    participant Gemini as Gemini

    U->>App: Select PDF
    App->>APIGW: POST /books/upload
    APIGW->>Books: Invoke
    Books->>DDB: Put initial book record (status=uploading)
    Books-->>App: {book_id, upload_url, s3_key}

    App->>S3: PUT PDF via presigned URL
    App->>APIGW: POST /books/{book_id}/confirm
    APIGW->>Books: Invoke
    Books->>S3: Get PDF
    Books->>DDB: Update total_pages + status=ready
    Books-->>App: Confirmed metadata

    App->>APIGW: POST /extractText {s3_key,start_page,page_count}
    APIGW->>Extract: Invoke
    Extract->>S3: Get PDF batch
    Extract-->>App: Extracted text chunk

    loop per chapter chunk
        App->>APIGW: POST /generateSummary
        APIGW->>Summary: Invoke
        Summary->>DDB: Cache lookup by chapter hash
        alt Cache miss
            Summary->>Gemini: Generate structured summary
            Gemini-->>Summary: JSON blocks
            Summary->>DDB: Store cached response
        end
        Summary-->>App: SummaryResponse
    end

    App->>APIGW: PUT /books/{book_id}/progress
    APIGW->>Books: Update reading state
```

## Sequence Diagram: Lazy Image Generation

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter App
    participant APIGW as API Gateway
    participant Img as Lambda generate_image.py
    participant Gemini as Gemini Image
    participant S3 as S3 Images Bucket
    participant Books as Lambda books.py

    App->>APIGW: POST /generateImage {prompt,style,...}
    APIGW->>Img: Invoke
    Img->>Gemini: Generate image bytes
    alt Gemini success
        Img->>S3: Put object generated/*.png
        Img-->>App: Presigned GET image_url
    else Gemini failure
        Img-->>App: Error / fallback URL path
    end

    App->>APIGW: PUT /books/{book_id}/progress {image_urls map}
    APIGW->>Books: Persist cross-device image URL cache
```

## Data Flow Diagram: End-to-End

```mermaid
flowchart LR
    A[PDF/TXT Input] --> B[Upload + Book Record]
    B --> C[S3 Object Storage]
    C --> D[Batch Text Extraction]
    D --> E[Chapter Chunking in App]
    E --> F[Summary API Calls]
    F --> G[Gemini Text Generation]
    G --> H[Structured Blocks]
    H --> I[Reading Feed Rendering]
    I --> J[On-demand Image Calls]
    J --> K[Gemini Image + S3 URL]
    K --> I
    I --> L[Progress + Image URL Sync]
    L --> M[DynamoDB user-books]
    F --> N[DynamoDB slides cache]
    O[Notes API] --> P[DynamoDB notes]
```

## Deployment View: Dual Backend Modes

```mermaid
flowchart TB
    subgraph DevMode[Local / Dev Mode]
        FlutterDev[Flutter App]
        FastAPI[FastAPI backend/main.py]
        MemCache[In-memory cache + notes]
        GeminiDev[Gemini APIs]
        FlutterDev --> FastAPI
        FastAPI --> MemCache
        FastAPI --> GeminiDev
    end

    subgraph ProdMode[AWS Serverless Mode]
        FlutterProd[Flutter App]
        APIGWProd[API Gateway]
        LambdasProd[Lambda handlers]
        DDBProd[(DynamoDB)]
        S3Prod[(S3)]
        CognitoProd[Cognito]
        GeminiProd[Gemini APIs]
        FlutterProd --> APIGWProd
        APIGWProd --> LambdasProd
        LambdasProd --> DDBProd
        LambdasProd --> S3Prod
        LambdasProd --> CognitoProd
        LambdasProd --> GeminiProd
    end
```
