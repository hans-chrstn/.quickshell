.pragma library

function retainExpandedWithoutPointer(attentionRequested, expandOnAttention) {
    return Boolean(attentionRequested) && Boolean(expandOnAttention);
}
