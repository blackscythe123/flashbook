"""
/auth/* — Cognito authentication endpoints.
POST /auth/signup  → create account (email + password)
POST /auth/login   → get tokens (id_token, access_token, refresh_token)
POST /auth/verify  → confirm signup with verification code
POST /auth/refresh → refresh expired tokens
"""
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}

_cognito = None


def _get_cognito():
    global _cognito
    if _cognito is None:
        _cognito = boto3.client("cognito-idp", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _cognito


def _ok(data: dict, code: int = 200) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}


def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


# ── Handlers ──────────────────────────────────────────────────────────────────

def _signup(body: dict) -> dict:
    email = body.get("email", "").strip().lower()
    password = body.get("password", "")

    if not email or not password:
        return _err(400, "email and password are required")
    if len(password) < 8:
        return _err(400, "Password must be at least 8 characters")

    client_id = os.environ["COGNITO_CLIENT_ID"]
    cognito = _get_cognito()

    try:
        resp = cognito.sign_up(
            ClientId=client_id,
            Username=email,
            Password=password,
            UserAttributes=[{"Name": "email", "Value": email}],
        )
        logger.info(f"Signup successful for {email}, sub={resp['UserSub']}")
        return _ok({
            "message": "Account created. Check your email for a verification code.",
            "user_id": resp["UserSub"],
            "email": email,
        }, 201)

    except cognito.exceptions.UsernameExistsException:
        return _err(409, "An account with this email already exists")
    except cognito.exceptions.InvalidPasswordException as e:
        return _err(400, f"Invalid password: {e.response['Error']['Message']}")
    except Exception as e:
        logger.error(f"Signup error: {e}")
        return _err(500, str(e))


def _verify(body: dict) -> dict:
    email = body.get("email", "").strip().lower()
    code = body.get("code", "").strip()

    if not email or not code:
        return _err(400, "email and code are required")

    client_id = os.environ["COGNITO_CLIENT_ID"]
    cognito = _get_cognito()

    try:
        cognito.confirm_sign_up(
            ClientId=client_id,
            Username=email,
            ConfirmationCode=code,
        )
        logger.info(f"Email verified for {email}")
        return _ok({"message": "Email verified successfully. You can now log in."})

    except cognito.exceptions.CodeMismatchException:
        return _err(400, "Invalid verification code")
    except cognito.exceptions.ExpiredCodeException:
        return _err(400, "Verification code has expired. Please request a new one.")
    except cognito.exceptions.NotAuthorizedException:
        return _err(400, "Account is already verified")
    except Exception as e:
        logger.error(f"Verify error: {e}")
        return _err(500, str(e))


def _login(body: dict) -> dict:
    email = body.get("email", "").strip().lower()
    password = body.get("password", "")

    if not email or not password:
        return _err(400, "email and password are required")

    client_id = os.environ["COGNITO_CLIENT_ID"]
    cognito = _get_cognito()

    try:
        resp = cognito.initiate_auth(
            ClientId=client_id,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": email,
                "PASSWORD": password,
            },
        )
        result = resp["AuthenticationResult"]
        logger.info(f"Login successful for {email}")
        return _ok({
            "id_token": result["IdToken"],
            "access_token": result["AccessToken"],
            "refresh_token": result["RefreshToken"],
            "expires_in": result["ExpiresIn"],
            "token_type": result["TokenType"],
        })

    except cognito.exceptions.NotAuthorizedException:
        return _err(401, "Incorrect email or password")
    except cognito.exceptions.UserNotConfirmedException:
        return _err(403, "Email not verified. Please check your email for the verification code.")
    except cognito.exceptions.UserNotFoundException:
        return _err(404, "No account found with this email")
    except Exception as e:
        logger.error(f"Login error: {e}")
        return _err(500, str(e))


def _refresh(body: dict) -> dict:
    refresh_token = body.get("refresh_token", "")

    if not refresh_token:
        return _err(400, "refresh_token is required")

    client_id = os.environ["COGNITO_CLIENT_ID"]
    cognito = _get_cognito()

    try:
        resp = cognito.initiate_auth(
            ClientId=client_id,
            AuthFlow="REFRESH_TOKEN_AUTH",
            AuthParameters={
                "REFRESH_TOKEN": refresh_token,
            },
        )
        result = resp["AuthenticationResult"]
        return _ok({
            "id_token": result["IdToken"],
            "access_token": result["AccessToken"],
            "expires_in": result["ExpiresIn"],
            "token_type": result["TokenType"],
        })

    except cognito.exceptions.NotAuthorizedException:
        return _err(401, "Refresh token expired. Please log in again.")
    except Exception as e:
        logger.error(f"Refresh error: {e}")
        return _err(500, str(e))


# ── Router ────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    path: str = event.get("path", "")
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _err(400, "Invalid JSON body")

    if path.endswith("/signup"):
        return _signup(body)
    elif path.endswith("/login"):
        return _login(body)
    elif path.endswith("/verify"):
        return _verify(body)
    elif path.endswith("/refresh"):
        return _refresh(body)
    else:
        return _err(404, "Route not found")
