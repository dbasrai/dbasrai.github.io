# https://pubmed.ncbi.nlm.nih.gov/28279349/
[https://pubmed.ncbi.nlm.nih.gov/28279349/](https://pubmed.ncbi.nlm.nih.gov/28279349/)

This paper focuses on ways to think about using causal pertubations like optogenetics to find a neural code.

## when can we use the word causal

When we first want to think about how the activity of neurons gives rise to some sort of output, just from recording data we can find correlations (for instance, neuron N is correlated to behavior M). However, if we want to see if neuron N causes behavior M, we need to experimentally control neuron N directly. This is the main theme of the beginning, in order to even use the world causal, we need to randomize the causal variable. This is easiest to think about for sensory stuff. If we want to see if sensory stimuli causes neuron N activity, then we need to randomize the stimuli (they use randomize which i think is just synonymous with control). Causal only refers to when we randomize the causal variable, not anything further down the chain. 

## on-manifold vs off-manifold

this is the main idea of the paper. Manifold refers to the state space of activity patterns that is visited during NORMAL recording of the behavior, wahts happening in question, BEFORE the pertubation. I think just think of the manifold is a pattern of activity (either neural or behavioral) that has been seen before. I also think the interpretation is also patterns of activity that can be INTERPOLATED between patterns of activity when seen before. Think about plotting points on state space, and then coloring in-between the lines. 

the manifold of the causal variable (neuron N) can be correlated to the manfifold of the effector variable (behavior M). 

jazayeris big point is that leaping to causal conclusions requires that the pertubation be On-Manifold. If neuron N is perturbed on manifold, and these leads to behavior M that is on-manifold (and I guess also follows what is correlated during normal behvaior), then we're quite happy. However, if neuron N is perturbed OFF-MANIFOLD, and these leads to behavior M that is either on or off manifold, i think the story is more complicated. I think there's a complex sort of permutations of ON or OFF manfiold pertubations, and whether the effector is changed ON or OFF manfiold, but I think the story is that we can't always neatly say that if we pertub N, that means that it causes what is seen in M. 





