import json
import re

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

def print_mismatches():
    with open('/home/allwin/Projects/indian-bank-sms-ner/data/gold_dataset.jsonl') as f:
        lines = f.readlines()

    ref_misses = 0
    acc_misses = 0
    for line in lines:
        if not line.strip(): continue
        data = json.loads(line)
        if data.get('intent') not in ['TRANSACTION', 'REFUND', 'REVERSAL']: continue
        text = data['raw_body']
        entities = data.get('entities', {})

        # Ref check
        exp_ref = str(entities.get('REFERENCE_ID') or '').strip()
        if exp_ref and len(exp_ref) > 4:
            clean = text.replace('\n', ' ').strip()
            match = refIdRegex.search(clean)
            refId = None
            if match:
                refId = match.group(1) or match.group(2) or match.group(3)
            if not refId or refId.lower() != exp_ref.lower():
                if ref_misses < 20:
                    print(f"REF MISMATCH: Expected: {exp_ref}, Got: {refId}, Text: {text}")
                ref_misses += 1

        # Acc check
        exp_acc = (entities.get('ACCOUNT') or entities.get('CARD') or '').strip()
        if exp_acc:
            clean = text.replace('\n', ' ').strip()
            match = accountRegex.search(clean)
            accNumber = None
            if match:
                accNumber = match.group(1) or match.group(2) or match.group(3)
            clean_exp = re.sub(r'[^a-z0-9]', '', exp_acc.lower())
            clean_res = re.sub(r'[^a-z0-9]', '', (accNumber or '').lower())
            
            if not (clean_exp in clean_res or (len(clean_res) > 3 and clean_res in clean_exp)):
                if acc_misses < 20:
                    print(f"ACC MISMATCH: Expected: {exp_acc}, Got: {accNumber}, Text: {text}")
                acc_misses += 1

print_mismatches()
