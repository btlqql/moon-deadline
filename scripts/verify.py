"""Standalone independent oracles; only Python stdlib, MoonBit and Node required."""
from pathlib import Path
import itertools,json,math,os,random,subprocess,wave
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'_build/oracle';WORK.mkdir(parents=True,exist_ok=True)
R=random.Random(20261031)
MOON=os.environ.get('MOON_BIN','moon')
def invoke(args):
    p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    assert p.returncode==0,(args,p.stdout,p.stderr)
    return p.stdout
invoke([MOON,'build','--target','js','--deny-warn'])
def request(data,ok=True):
    path=WORK/'request.json';path.write_text(json.dumps(data),encoding='utf-8')
    p=subprocess.run(['node',str(ROOT/'_build/js/debug/build/cmd/main/main.js'),str(path)],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    result=json.loads(p.stdout)
    assert result['ok']==ok and (p.returncode==0)==ok,(p.stdout,p.stderr)
    return result

def fits(tasks):
    for last,t in enumerate(tasks):
        jobs=[];complete=False
        for time in range(t['deadline']):
            for i,h in enumerate(tasks[:last+1]):
                if time%h['period']==0:jobs.append([i,time,h['cost']])
            active=min((j for j in jobs if j[2]),default=None,key=lambda x:(x[0],x[1]))
            if active:
                active[2]-=1
                if active[0]==last and active[1]==0 and active[2]==0:complete=True;break
        if not complete:return False
    return True
for case in range(48):
    tasks=[dict(name=str(i),cost=R.randrange(1,4),period=p,deadline=R.randrange(2,p+1),jitter=0,blocking=0)
           for i,p in enumerate(R.choices([4,5,8,10],k=3))]
    result=request(dict(tasks=tasks,horizon=80,optimize=True,before=tasks[::-1]))
    assert all(r['meets_deadline'] for r in result['response'])==fits(tasks)
    exists=any(fits(list(order)) for order in itertools.permutations(tasks))
    assignment=result['planning']['assignment']
    assert (assignment is not None)==exists
    if assignment:assert fits([tasks[i] for i in assignment['order']])
    for i in range(3):
        costs=[]
        for c in range(1,tasks[i]['deadline']+1):
            trial=[dict(t) for t in tasks];trial[i]['cost']=c
            if fits(trial):costs.append(c)
        assert result['planning']['maximum_cost_in_original_order'][i]==(max(costs) if costs else None)
    assert [c['name'] for c in result['comparison']]==[t['name'] for t in tasks[::-1]]
    for c in result['comparison']:
        assert (c['after_upper'] is not None)==c['after_feasible']
        assert (c['before_upper'] is not None)==c['before_feasible']
bad=json.loads((ROOT/'examples/config-regression.json').read_text());bad['tasks'][0]['period']=0
request(bad,False)
report={'status':'passed','seed':20261031,'priority_budget_and_named_regression_models':48}

(WORK/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
