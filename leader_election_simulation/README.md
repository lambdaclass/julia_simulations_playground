# Leader Election Simulation

## Installing Dependencies

```
make install
```

## Run the Simulation

```
make run
```

## Simulation

In this scenario we want to simulate every validator's wealth's evolution given that it was elected as leader and its block proposal was accepted or not.

### Setup

To setup this scenario we need to create validators pool with $n$ validators, each of which has to stake a certain amount of credits $c$.

### Leader Election

This can be modeled as a weighted random choice based on the validator's stake or as a equiprobable random choice.

### Proposal Acceptance

We can model this as a random variable with Bernoulli distribution with probability $p$ of success such that

$$
LP: \text{"Leader's proposal was accepted"} \\
LP \thicksim Bernoulli(p) 
$$

### Reward Reinvestment

We can model this as a random variable with Bernoulli distribution with probability $p$ of success such that

$$
RR: \text{"Leader reinvests proposal's reward"} \\
RR \thicksim Bernoulli(p) 
$$

### Different Behaviour

Until now we have four parameters:

- Initial stake.
- Leader election protocol.
- Proposal acceptance.
- Reward reinvestment.



We cut the cases where Proposal Acceptance is 0 because without acceptance the system won't change from its initial state.

| Initial Stake | Leader Election Protocol | Proposal Acceptance | Reward Reinvestment |
| ------------- | ------------------------ | ------------------- | ------------------- |
| $=$ | Weighted | $\frac{1}{2}$ | 0 |
| $=$ | Weighted | $\frac{1}{2}$ | $\frac{1}{2}$ |
| $=$ | Weighted | $\frac{1}{2}$ | 1 |
| $=$ | Weighted | 1 | 0 |
| $=$ | Weighted | 1 | $\frac{1}{2}$ |
| $=$ | Weighted | 1 | 1 |
| $=$ | Not Weighted | $\frac{1}{2}$ | 0 |
| $=$ | Not Weighted | $\frac{1}{2}$ | $\frac{1}{2}$ |
| $=$ | Not Weighted | $\frac{1}{2}$ | 1 |
| $=$ | Not Weighted | 1 | 0 |
| $=$ | Not Weighted | 1 | $\frac{1}{2}$ |
| $=$ | Not Weighted | 1 | 1 |
| $\neq$ | Weighted | $\frac{1}{2}$ | 0 |
| $\neq$ | Weighted | $\frac{1}{2}$ | $\frac{1}{2}$ |
| $\neq$ | Weighted | $\frac{1}{2}$ | 1 |
| $\neq$ | Weighted | 1 | 0 |
| $\neq$ | Weighted | 1 | $\frac{1}{2}$ |
| $\neq$ | Weighted | 1 | 1 |
| $\neq$ | Not Weighted | $\frac{1}{2}$ | 0 |
| $\neq$ | Not Weighted | $\frac{1}{2}$ | $\frac{1}{2}$ |
| $\neq$ | Not Weighted | $\frac{1}{2}$ | 1 |
| $\neq$ | Not Weighted | 1 | 0 |
| $\neq$ | Not Weighted | 1 | $\frac{1}{2}$ |
| $\neq$ | Not Weighted | 1 | 1 |

So, to translate this cases to scenarios we have:

All validators start with the same stake or with different stakes. A validator is elected as leader based on the amount of its stake or equiprobably. The leader's block proposal is accepted with probability $p = \frac{1}{2}$, if accepted it is rewarded else it isn't. Finally the leader reinvest the reward with probability $p = \frac{1}{2}$, if reinvests it starts the next round with more stake else it maintains the same stake from the previous round.
