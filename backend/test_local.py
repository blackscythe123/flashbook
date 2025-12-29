"""
Quick test script for local development.
Run: python test_local.py
"""

import requests
import json

BASE_URL = "http://localhost:8080"

# Test chapter text (from Atomic Habits)
TEST_CHUNK = """
The 1% Rule states that small improvements compound over time. If you get 1% better each day, you will be 37 times better after one year. This is the power of atomic habits - tiny changes that deliver remarkable results.

The key is consistency over intensity. Most people overestimate what they can do in a day and underestimate what they can achieve in a year. Focus on systems, not goals. Goals are about the results you want to achieve. Systems are about the processes that lead to those results.

If you want better results, forget about setting goals. Focus on your system instead. You do not rise to the level of your goals. You fall to the level of your systems. Bad habits repeat themselves not because you don't want to change, but because you have the wrong system for change.

The most effective way to change your habits is to focus not on what you want to achieve, but on who you wish to become. Your identity emerges out of your habits. Every action is a vote for the type of person you wish to become.
"""

def test_health():
    """Test health endpoint."""
    print("\n🔍 Testing /health...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"   Status: {response.status_code}")
    print(f"   Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_generate_summary():
    """Test summary generation."""
    print("\n🤖 Testing /generateSummary...")
    
    payload = {
        "text_chunk": TEST_CHUNK,
        "mode": "chapter",
        "chapter_title": "The Power of Tiny Gains",
        "book_id": "atomic-habits"
    }
    
    response = requests.post(
        f"{BASE_URL}/generateSummary",
        json=payload,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"   Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"   Unit Title: {data['unit_title']}")
        print(f"   Blocks: {len(data['blocks'])}")
        print(f"   Cached: {data['cached']}")
        print("\n   Blocks:")
        for i, block in enumerate(data['blocks'], 1):
            text_preview = block['text'][:80] + "..." if len(block['text']) > 80 else block['text']
            print(f"      {i}. [{block['type']}] {text_preview}")
    else:
        print(f"   Error: {response.text}")
    
    return response.status_code == 200

def test_cache():
    """Test cache functionality."""
    print("\n💾 Testing cache (second request should be cached)...")
    
    payload = {
        "text_chunk": TEST_CHUNK,
        "mode": "chapter",
        "chapter_title": "The Power of Tiny Gains",
        "book_id": "atomic-habits"
    }
    
    response = requests.post(
        f"{BASE_URL}/generateSummary",
        json=payload
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"   Cached: {data['cached']}")
        return data['cached'] == True
    
    return False

def test_cache_stats():
    """Test cache stats endpoint."""
    print("\n📊 Testing /cache/stats...")
    response = requests.get(f"{BASE_URL}/cache/stats")
    print(f"   Status: {response.status_code}")
    print(f"   Stats: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


if __name__ == "__main__":
    print("=" * 50)
    print("Flashbook AI Backend - Local Test")
    print("=" * 50)
    print(f"Target: {BASE_URL}")
    print("Make sure the server is running: python main.py")
    
    results = []
    
    try:
        results.append(("Health Check", test_health()))
        results.append(("Generate Summary", test_generate_summary()))
        results.append(("Cache Hit", test_cache()))
        results.append(("Cache Stats", test_cache_stats()))
    except requests.exceptions.ConnectionError:
        print("\n❌ Connection failed! Is the server running?")
        print("   Run: python main.py")
        exit(1)
    
    print("\n" + "=" * 50)
    print("Results:")
    print("=" * 50)
    
    all_passed = True
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {status} - {name}")
        if not passed:
            all_passed = False
    
    print("\n" + ("🎉 All tests passed!" if all_passed else "⚠️ Some tests failed"))
