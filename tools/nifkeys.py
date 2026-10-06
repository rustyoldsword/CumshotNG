import struct,sys
def parse(p):
    b=open(p,'rb').read()
    i=b.index(b'\n')+1
    ver,=struct.unpack_from('<I',b,i); i+=4
    i+=1 # endian
    user,=struct.unpack_from('<I',b,i); i+=4
    nblocks,=struct.unpack_from('<I',b,i); i+=4
    bsver,=struct.unpack_from('<I',b,i); i+=4
    for _ in range(3):  # author, process, export (byte len strings)
        l=b[i]; i+=1+l
    nt,=struct.unpack_from('<H',b,i); i+=2
    types=[]
    for _ in range(nt):
        l,=struct.unpack_from('<I',b,i); i+=4; types.append(b[i:i+l].decode()); i+=l
    idx=struct.unpack_from('<%dH'%nblocks,b,i); i+=2*nblocks
    sizes=struct.unpack_from('<%dI'%nblocks,b,i); i+=4*nblocks
    ns,=struct.unpack_from('<I',b,i); i+=4
    maxl,=struct.unpack_from('<I',b,i); i+=4
    strs=[]
    for _ in range(ns):
        l,=struct.unpack_from('<I',b,i); i+=4; strs.append(b[i:i+l].decode('latin1')); i+=l
    ng,=struct.unpack_from('<I',b,i); i+=4+4*ng
    out=[]
    for k in range(nblocks):
        out.append((k,types[idx[k]],b[i:i+sizes[k]])); i+=sizes[k]
    return out,strs
def keys(t,d):
    n,=struct.unpack_from('<I',d,0)
    if n==0: return []
    it,=struct.unpack_from('<I',d,4); o=8; r=[]
    for _ in range(n):
        if t=='NiBoolData':
            tm,v=struct.unpack_from('<fB',d,o); o+=5
            if it==2: o+=2
            elif it==3: o+=12
        else:
            tm,v=struct.unpack_from('<ff',d,o); o+=8
            if it==2: o+=8
            elif it==3: o+=12
        r.append((round(tm,2),round(v,2)))
    return it,r
if __name__=="__main__":
  for p in sys.argv[1:]:
     bl,strs=parse(p); print('==',p.split('/')[-1])
     for k,t,d in bl:
         if t in('NiBoolData','NiFloatData'): print(k,t,keys(t,d))
         if t=='NiControllerSequence':
             # name(stringidx) ... just print floats near end
             print(k,t,strs[struct.unpack_from('<I',d,0)[0]])
         if t=='NiTextKeyExtraData':
             nm=struct.unpack_from('<I',d,0)[0]; n=struct.unpack_from('<I',d,4)[0]; o=8; ks=[]
             for _ in range(n):
                 tm,si=struct.unpack_from('<fI',d,o); o+=8; ks.append((round(tm,2),strs[si]))
             print(k,t,ks)
