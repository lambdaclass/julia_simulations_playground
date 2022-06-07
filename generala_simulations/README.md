# Generala Simulations

## Generala Rules

Generala is a game played by two or more players. Players take turns rolling five dice. After each roll, the player chooses which dice (if any) to keep, and which to reroll. A player may reroll some or all of the dice up to three times on a turn.

## Scoring

The following combinations earn points:

- Ones, Twos, Threes, Fours, Fives or Sixes. A player may add the numbers on any combination of dice showing the same number. 
- Straight. A straight is a combination of five consecutive numbers (1-2-3-4-5, or 2-3-4-5-6); it also includes consecutive numbers with 6 and 1, such as 3-4-5-6-1. In essence, any set of five unmatched dice are a straight.
- Full. Any set of three combined with a set of two. For example, 5-5-5-3-3.
- Poker. Four dice with the same number. For example, 2-2-2-2-6.
- Generala. All five dice with the same number.
- Double Generala (optional). 100 or 120 points. All five dice with the same number for the second time in a game.

If a player makes a Straight, Full House, or Four of a Kind on the first roll of a given turn, it is called served. A player who makes Generala on the first roll of a turn automatically wins the game.

## Probability Calculations

$$
\begin{align*}
\mathbb{P}("\text{Served Generala}") &= 6\bigg(\frac{1}{6}\bigg)^5 \\
                                     &= 0.0007716049382716055
\end{align*}
$$

$$
\begin{align*}
\mathbb{P}("\text{Served Full}") &= 6\bigg(\frac{1}{6}\bigg)^3 \cdot 5\bigg(\frac{1}{6}\bigg)^2 \\
                                     &= 0.003858024691358024
\end{align*}
$$

$$
\begin{align*}
\mathbb{P}("\text{Served Poker}") &= 6\bigg(\frac{1}{6}\bigg)^4 \cdot 5\bigg(\frac{5}{6}\bigg) \\
                                     &= 0.01929012345679011
\end{align*}
$$

$$
\begin{align*}
\mathbb{P}("\text{Served Straight}") &= \frac{5}{6} \cdot \frac{4}{6} \cdot \frac{3}{6} \cdot \frac{2}{6} \cdot \frac{1}{6}  \\
                                     &= 0.030864197530864196
\end{align*}
$$

## Simulation (estimation)

In practice saying that an event $A$ happens with a determined probability $\mathbb{P}(A) = p$ is equivalent to say that in big enough series of experiments the relative frequencies of event $A$ happening

$$\hat{p}_{k}(A) = \frac{n_{k}(A)}{n_{k}}$$

(where $n_k$ is the amount of tests carried out in the $k$-iest series and $n_k(A)$ is the amount of times $A$ happens) are approximately identical to each other and are close to $p$. The series of experiments can be simulated on a computer using a random number generator.

The experiment consists in throwing five dice and registering the results. The set of all possible throws is described by

$$\Omega = \big\{\{d_1, d_2, d_3, d_4, d_5\}: d_i \in \{1, 2, 3, 4, 5, 6\}\big\}$$
$$|\Omega| = 6^5$$

