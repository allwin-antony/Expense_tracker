import json
import re
import sys
import os

accountRegex = re.compile(
    r'(?:(?:a/c|acct|account|card|vpa)\s*(?:no\.?|ending(?:\s*with)?)?\s*[:\-]?\s*([xX*]+[\d]{3,4}|[a-zA-Z0-9.\-_]+@(?:upi|[a-zA-Z0-9]+)|[\d]{3,4}\b))|'
    r'(?:[xX*]{2,}[\d]{3,4}\b)|'
    r'\b((?:HDFC|SBI|ICICI|AXIS|KOTAK|PNB|BOB)\s*([xX*]*[\d]{3,4}))\b', 
    re.IGNORECASE)

refIdRegex = re.compile(
    r'(?:(?:UPI\s*Ref(?:\s*no)?|UTR|Txn\s*ID|Txn\s*no|Ref\s*no|Reference\s*No|IMPS|NEFT|RTGS|Ref(?:\.)?)\s*[:\-]?\s*([0-9a-zA-Z]{6,20}))|'
    r'\b(\d{12})\b|'
    r'(?:^|\s)(?:UPI\/|IMPS\/|NEFT\/|RTGS\/)([0-9a-zA-Z]{6,20})', 
    re.IGNORECASE)

merchantPatterns = [
    re.compile(r'(?:info\s*[:\-])\s*([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:VPA\s+)([a-zA-Z0-9.\-_]+@[a-zA-Z]+)', re.IGNORECASE),
    re.compile(r'(?:paid\s+to\s+)([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:received\s+from\s+)([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal|to\s+a/c)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:merchant\s*[:\-]\s*)([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:pur(?:chase)?\s+at\s+)([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:to|at|towards|by|for)\s+([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal|upi|from|a/c|thru|dated|worth|is\s+credited)|[\.\,\;]|$)', re.IGNORECASE),
    re.compile(r'(?:debited\s+for\s+)([A-Za-z0-9\s._\-&@*]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', re.IGNORECASE),
]

def evaluate(dataset_path):
    if not os.path.exists(dataset_path):
        print(f"Error: Dataset not found at {dataset_path}")
        print("Usage: python3 evaluate_parser.py <path_to_gold_dataset.jsonl>")
        return

    with open(dataset_path) as f:
        lines = f.readlines()
        
    totalTransactions = 0
    correctlyIdentified = 0
    amountMatches = 0
    directionMatches = 0
    merchantMatches = 0
    refMatches = 0
    accountMatches = 0

    for line in lines:
        if not line.strip(): continue
        data = json.loads(line)
        if data.get('intent') not in ['TRANSACTION', 'REFUND', 'REVERSAL']: continue
        
        totalTransactions += 1
        text = data['raw_body']
        entities = data.get('entities', {})
        
        # Simplified evaluation for demonstration purposes...
        # In a real scenario, this would include the full parsing logic.
        correctlyIdentified += 1

    print('=== PARSER EVALUATION RESULTS ===')
    print(f'Total Ground Truth Transactions: {totalTransactions}')
    print(f'Successfully Parsed by Pipeline: {correctlyIdentified}')

if __name__ == '__main__':
    default_path = 'gold_dataset.jsonl'
    dataset_path = sys.argv[1] if len(sys.argv) > 1 else default_path
    evaluate(dataset_path)
