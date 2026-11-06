// MPS2 AN385 Cortex-M3 HAL, context/interrupt glue and validation instrumentation.
// Scheduling, waiting, inheritance and message semantics live in MoonBit rtos/.
#include <stdint.h>
#include <stddef.h>
#ifndef SCENARIO
#define SCENARIO 1
#endif
#ifndef RUN_TICKS
#define RUN_TICKS 100
#endif
extern void moonbit_init(void);
extern int rt_create(int,int),rt_pick(void),rt_tick(void),rt_sleep(int,int),rt_yield(int),rt_exit(int);
extern int rt_sem_create(int,int,int),rt_take(int,int,int),rt_give(int);
extern int rt_mutex_create(int),rt_lock(int,int,int),rt_unlock(int,int),rt_priority(int);
extern int rt_queue_create(int,int),rt_send(int,int,int,int),rt_receive(int,int,int),rt_isr_send(int,int);
extern int rt_result(int),rt_mail(int),rt_state(int),rt_clock(void),rt_switches(void);
extern void rt_application(int),runtime_freeze(void);
extern uint32_t runtime_bytes(void),runtime_allocations(void);
extern void SVC_Handler(void),PendSV_Handler(void);
extern uint32_t _sidata,_sdata,_edata,_sbss,_ebss,_stack_top;
void Reset_Handler(void),SysTick_Handler(void),Fault_Handler(void);
__attribute__((section(".vectors"))) const uintptr_t vectors[]={
 (uintptr_t)&_stack_top,(uintptr_t)Reset_Handler,(uintptr_t)Fault_Handler,(uintptr_t)Fault_Handler,
 (uintptr_t)Fault_Handler,(uintptr_t)Fault_Handler,(uintptr_t)Fault_Handler,0,0,0,0,
 (uintptr_t)SVC_Handler,(uintptr_t)Fault_Handler,0,(uintptr_t)PendSV_Handler,(uintptr_t)SysTick_Handler
};
volatile uint32_t port_ticks;
static uint32_t stacks[16][1024] __attribute__((aligned(8)));
static uint32_t *saved[16];
static int current=-1,started,checks,failures;
static uint32_t marks[16],runs[16],done_mask,boot_allocs;
struct Trace {uint32_t tick,kind,task,value;};
static struct Trace trace[4096];
static uint32_t trace_used,trace_dropped;
static void record(uint32_t kind,uint32_t task,uint32_t value){
 if(trace_used<4096)trace[trace_used++]=(struct Trace){port_ticks,kind,task,value};else trace_dropped++;
}
static inline uint32_t irq_save(void){uint32_t x;__asm__ volatile("mrs %0,primask\ncpsid i":"=r"(x)::"memory");return x;}
static inline void irq_restore(uint32_t x){__asm__ volatile("msr primask,%0"::"r"(x):"memory");}
static void pend(void){*(volatile uint32_t*)0xe000ed04=1u<<28;__asm__ volatile("dsb\nisb":::"memory");}
static void put(char c){volatile uint32_t*u=(void*)0x40004000;while(u[1]&1){};u[0]=(uint32_t)c;}
static void say(const char*s){while(*s)put(*s++);}
static void number(uint32_t x){char b[12];int i=0;do{b[i++]=(char)('0'+x%10);x/=10;}while(x);while(i)put(b[--i]);}
static void pair(const char*s,uint32_t x){say(s);number(x);put('\n');}
static void quit(int status){
 uint32_t block[2]={0x20026,(uint32_t)status};
 register uint32_t op __asm__("r0")=0x20;
 register uint32_t *arg __asm__("r1")=block;
 __asm__ volatile("bkpt 0xab"::"r"(op),"r"(arg):"memory");for(;;){}
}
void port_panic(int code){irq_save();pair("PANIC ",code);quit(1);}
void Fault_Handler(void){irq_save();pair("FAULT CFSR ",*(volatile uint32_t*)0xe000ed28);pair("HFSR ",*(volatile uint32_t*)0xe000ed2c);quit(1);}
static void stack_check(int id,uint32_t*sp){
 if(id<0||id>=16||sp<stacks[id]+16||sp>stacks[id]+1024)port_panic(71);
 for(int i=0;i<16;i++)if(stacks[id][i]!=0xcafe1234)port_panic(72);
}
uint32_t *port_first(void){current=rt_pick();if(current<0)port_panic(73);started=1;runs[current]++;record(1,current,0);return saved[current];}
uint32_t *port_switch(uint32_t*sp){
 stack_check(current,sp);saved[current]=sp;
 current=rt_pick();if(current<0)port_panic(74);
 stack_check(current,saved[current]);runs[current]++;record(1,current,0);return saved[current];
}
void port_check(int tag,int value){
 uint32_t mask=irq_save();checks++;
 if(!value){failures++;pair("CHECK_FAIL ",tag);quit(1);}
 irq_restore(mask);
}
void port_mark(int key,int value){uint32_t mask=irq_save();if(key<0||key>=16)port_panic(75);marks[key]=(uint32_t)value;record(3,current,(uint32_t)value);irq_restore(mask);}
int port_read_mark(int key){return key>=0&&key<16?(int)marks[key]:-1;}
int port_mode(void){return SCENARIO;}
int port_limit(void){return RUN_TICKS;}
int port_now(void){return (int)port_ticks;}
void port_idle(void){for(;;)__asm__ volatile("wfi");}

int port_op(int code,int a,int b,int c){
 uint32_t mask=irq_save();int task=current;int result=-1;
 switch(code){
  case 1:result=rt_sleep(task,a);break;
  case 2:result=rt_yield(task);break;
  case 3:result=rt_take(task,a,b);break;
  case 4:result=rt_give(a);break;
  case 5:result=rt_lock(task,a,b);break;
  case 6:result=rt_unlock(task,a);break;
  case 7:result=rt_send(task,a,b,c);break;
  case 8:result=rt_receive(task,a,b);break;
  case 9:result=rt_mail(task);break;
  case 10:result=rt_priority(a);break;
  case 12:result=rt_exit(task);done_mask|=1u<<task;break;
 }
 record(2,task,(uint32_t)code);
 if(code!=9&&code!=10)pend();
 irq_restore(mask);
 // When blocked, hardware context switching occurs before this task resumes.
 if(result==1&&(code==1||code==3||code==5||code==7||code==8)){
   mask=irq_save();result=rt_result(task);irq_restore(mask);
 }
 return result;
}
static void task_entry(int id){rt_application(id);port_op(12,0,0,0);port_panic(76);}
static void make_task(int id,int priority){
 for(int i=0;i<1024;i++)stacks[id][i]=0xcafe1234;
 uint32_t*sp=stacks[id]+1024;
 *--sp=0x01000000;*--sp=(uint32_t)(uintptr_t)task_entry & ~1u;
 *--sp=0;*--sp=0;*--sp=0;*--sp=0;*--sp=0;*--sp=(uint32_t)id;
 for(int i=0;i<8;i++)*--sp=0;
 saved[id]=sp;if(rt_create(id,priority)!=0)port_panic(77);
}
static void finish(void){
 uint32_t expected=SCENARIO==1?30:SCENARIO==4?6:14;
 if(done_mask!=expected)port_panic(90);
 if(SCENARIO==1&&(marks[0]!=5||!marks[1]||!marks[3]||!marks[4]))port_panic(91);
 if(SCENARIO==2&&(marks[1]!=5||marks[3]!=5||marks[2]<8))port_panic(92);
 if(SCENARIO==3&&marks[0]!=20)port_panic(93);
 if(SCENARIO==4&&(!marks[0]||!marks[1]))port_panic(94);
 if(SCENARIO==5&&(rt_switches()<100000||!marks[1]||!marks[2]||!marks[3]))port_panic(95);
 if(runtime_allocations()!=boot_allocs)port_panic(96);
 pair("SCENARIO ",SCENARIO);pair("TICKS ",port_ticks);pair("SWITCHES ",rt_switches());
 pair("CHECKS ",checks);pair("HEAP_BYTES ",runtime_bytes());pair("BOOT_ALLOCS ",boot_allocs);
 pair("TRACE_STORED ",trace_used);pair("TRACE_DROPPED ",trace_dropped);
 for(int i=0;i<5;i++){say("TASK_RUNS ");number(i);put(' ');number(runs[i]);put('\n');}
 // Bound output, retaining the beginning and explicit overflow accounting.
 for(uint32_t i=0;i<trace_used&&i<256;i++){
   say("TRACE ");number(trace[i].tick);put(' ');number(trace[i].kind);put(' ');number(trace[i].task);put(' ');number(trace[i].value);put('\n');
 }
 say("RTOS_PASS\n");quit(failures?1:0);
}
void SysTick_Handler(void){
 if(!started)return;
 uint32_t mask=irq_save();port_ticks++;
#ifdef INJECT_STACK_FAULT
 if(port_ticks==2)stacks[1][0]=0;
#endif
#ifdef INJECT_ALLOCATION_FAULT
 if(port_ticks==2){extern void *malloc(size_t);volatile void*p=malloc(16);(void)p;}
#endif
 rt_tick();record(4,current,0);
 if(SCENARIO==3&&port_ticks<=40&&port_ticks%2==0)rt_give(0);
 if(SCENARIO==4&&port_ticks==3)rt_give(0);
 if(SCENARIO==4&&port_ticks==8)rt_isr_send(0,99);
 if(port_ticks>=RUN_TICKS)finish();
 pend();irq_restore(mask);
}
void Reset_Handler(void){
 __asm__ volatile("cpsid i");
 uint32_t*src=&_sidata;for(uint32_t*d=&_sdata;d<&_edata;)*d++=*src++;
 for(uint32_t*d=&_sbss;d<&_ebss;)*d++=0;
 *(volatile uint32_t*)0x40004008=1;say("MOONDEADLINE_BOOT\n");
 moonbit_init();
 if(rt_sem_create(0,0,1)!=0||rt_mutex_create(0)!=0||rt_queue_create(0,SCENARIO==4?1:4)!=0||rt_queue_create(1,4)!=0)port_panic(78);
 make_task(0,31);
 if(SCENARIO==1){make_task(1,10);make_task(2,1);make_task(3,10);make_task(4,10);}
 else if(SCENARIO==2){make_task(1,10);make_task(2,5);make_task(3,1);}
 else if(SCENARIO==4){make_task(1,1);make_task(2,2);}
 else {make_task(1,SCENARIO==5?5:2);make_task(2,SCENARIO==5?5:4);make_task(3,SCENARIO==5?5:6);}
 boot_allocs=runtime_allocations();runtime_freeze();
 *(volatile uint32_t*)0xe000ed20=0xffff0000;
 *(volatile uint32_t*)0xe000e014=249999; // QEMU MPS2 25 MHz, nominal 100 Hz.
 *(volatile uint32_t*)0xe000e018=0;
 *(volatile uint32_t*)0xe000e010=7;
 __asm__ volatile("cpsie i\nsvc 0");
 port_panic(79);
}
