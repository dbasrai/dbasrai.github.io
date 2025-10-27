an attempt to view a lot of common terms through one way of neuroscience thinking. meant for neuroscientists who get a lil nervous when they see an uppercase sigma.

## 

we want to know how the brain creates behavior. We record two neurons, and count how many times they spiked.

[2, 10]

we then record how many times the mouse freezed. the mouse freezed 5 times.

we want to come up with a RULE that generates freezing. this rule must be linear. 

A first attempt would be to add up the two neurons spikes, and maybe that generates freezing. how would we write out description of this rule AGNOSTICALLY to the value. 

[1;1]...  [1*2 + 1*10] = 12. 12!=5. its a dumb rule.

the average doesn't work either. [1/num_neurons_recorded;1/num_neurons_recorded], which will be [1/2; 1/2], which will be 1/2*2 + 1/2*10 = 6. which is better, but not 5.

there's a lot of RULES for this one value that do make 5. In order to get the universal rules, we need more data.

[2,10] -> 5 freezes


