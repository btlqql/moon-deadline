// Bounded static-lifetime runtime adapter for the pinned MoonBit-generated C.
// Uses the official moonbit.h ABI; allocations allowed only during boot.
#include "moonbit.h"
#include "moonbit_runtime.h"
#include <stdint.h>
extern void port_panic(int);
static uint64_t arena[8192];
static uint32_t used, allocations, frozen;
const uint32_t *moonbit_layout_table;
void *memcpy(void *dst,const void *src,size_t n){unsigned char*d=dst;const unsigned char*s=src;while(n--)*d++=*s++;return dst;}
void *memset(void *dst,int v,size_t n){unsigned char*d=dst;while(n--)*d++=(unsigned char)v;return dst;}
static void *reserve(size_t bytes){
  if(frozen)port_panic(81);
  bytes=(bytes+7)&~(size_t)7;
  if(bytes>sizeof(arena)-used)port_panic(82);
  void*p=(unsigned char*)arena+used;used+=bytes;allocations++;return p;
}
// The compiler also inlines regular-object allocation through libc malloc.
void *malloc(size_t bytes){return reserve(bytes);}
void free(void *ptr){if(ptr)port_panic(87);}
void *moonbit_malloc(size_t bytes){
  struct moonbit_object*h=reserve(bytes+sizeof(*h));
  Moonbit_init_dynamic_rc(h,moonbit_BLOCK_KIND_REGULAR);h->meta=0;return h+1;
}
void *moonbit_malloc_array(enum moonbit_block_kind kind,int shift,int32_t n){
  if(n<0||shift<0||shift>4)port_panic(83);
  struct moonbit_object*h=reserve(((size_t)n<<shift)+sizeof(*h));
  Moonbit_init_dynamic_rc(h,kind);h->meta=(uint32_t)n;return h+1;
}
int32_t *moonbit_make_int32_array(int32_t n,int32_t value){
  int32_t*a=moonbit_malloc_array(moonbit_BLOCK_KIND_VAL_ARRAY,2,n);
  for(int i=0;i<n;i++)a[i]=value;return a;
}
int64_t *moonbit_make_int64_array(int32_t n,int64_t value){
  int64_t*a=moonbit_malloc_array(moonbit_BLOCK_KIND_VAL_ARRAY,3,n);
  for(int i=0;i<n;i++)a[i]=value;return a;
}
void moonbit_incref(void*p){
  if(!p)return;struct moonbit_object*h=Moonbit_object_header(p);
  int rc=Moonbit_rc_count(h);if(rc<0)return;
  if(rc==0||rc>=0x3ffffff)port_panic(84);
  h->rc+=(1<<MOONBIT_RC_COUNT_SHIFT);
}
void moonbit_decref(void*p){
  if(!p)return;struct moonbit_object*h=Moonbit_object_header(p);
  int rc=Moonbit_rc_count(h);if(rc<0)return;
  // Objects in this adapter are permanent kernel resources, not a general heap.
  if(rc<=1)port_panic(85);
  h->rc-=(1<<MOONBIT_RC_COUNT_SHIFT);
}
_Noreturn void moonbit_panic(void){port_panic(86);__builtin_unreachable();}
void runtime_freeze(void){frozen=1;}
uint32_t runtime_bytes(void){return used;}
uint32_t runtime_allocations(void){return allocations;}
