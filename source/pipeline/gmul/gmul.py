
# coding: utf-8

# In[23]:


# @file gmul
# @author spike
def gmul(a, b, m, order = 16):
    p = 0
    for i in range(0,order):
        if (b % 2 == 1):
            p ^= a
        if (a // (2**(order-1)) == 1):
            a = ((a * 2)) ^ m;
        else:
            a = (a * 2)
        b = b // 2
    return p

print(hex(gmul(0x57, 0x13, 0x11b, order = 8)))
print(hex(gmul(0x1122, 0x0044, 0x13333)))
print(hex(gmul(0x11223344, 0x55667788, 0x199990000, order = 32)))

