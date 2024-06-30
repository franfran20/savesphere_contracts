# Savesphere V1: Your All-in-One Savings Application

Savesphere is an innovative savings application deployed on Meter, designed to enhance users' savings habits and help them achieve their financial goals. This platform allows users to manage their savings efficiently, whether individually or as part of a group. Users can save MTRG tokens, track their saving activities, and potentially earn interest on their savings.

Savesphere supports three main saving categories. `FlexSave` offers a flexible savings option that allows users to save for a specific period and earn interest, with the option to withdraw savings at any time. `TargetDrivenSave` enables users to set specific savings goals and unlock their savings only upon reaching those targets. `GroupSave` facilitates collective savings, allowing users to save together as a group and manage their savings collaboratively.

By providing these comprehensive features, Savesphere aims to foster better savings habits, encourage users to fulfill their financial desires, and ensure the proper management of their savings.

## Flex Save

FlexSave, as the name implies, is the flexible savings feature of SaveSphere. It allows users to set their saving amount and duration, pooling their savings with others. Users can earn interest from other savers who default due to personal reasons, enhancing the collaborative saving experience and encouraging users to save more.

The process of generating and distributing the interest pool in FlexSave operates as follows:

When users initiate a FlexSave with a specific amount and duration, they join a group of other participants. During their saving period, they have the opportunity to earn potential interest. At the end of their saving duration, they can withdraw their savings along with the accumulated interest.

During the saving period, users have the option to withdraw early, forfeiting the interest accrued up to that point and incurring a default fee (10% on testnet). This fee is deducted from the user's savings and added to the interest pool. The interest pool is then shared among savers who complete their saving duration, providing them with additional earnings.

The interest pool consists of MTRG tokens collected from users who default on their savings.

In summary,
`Users who complete their saving period earn interest from the default pool.`
`Users who do not complete their saving period lose a default percentage of their savings, which is added to the default pool.`

When the interest pool has a balance and there are savers, we calculate each saver’s potential interest based on their expected saving duration and amount saved. The potential interest for users fluctuates depending on the number of defaulters and savers.

To determine their potential interest at the end of their saving period and the current possible interest they've earned (if they don't default), we need to consider their saving details in relation to other savers.

First, get the amount saved by the user, `userAmountSaved`, and the total amount saved by all users on the flexSave contract, `totalAmountSaved`. The user’s amount share relative to other savers is:
`userAmountShare = (userAmountSaved / totalAmountSaved) * 100`

Get the user's expected saving time, referred to as `userSaveDuration`, because the user has not yet completed their savings but has the potential to do so. If they do not complete their savings, they are charged a default fee for breaking their savings commitment and for affecting the possible interest other users could have earned. Then, obtain the combined expected saving durations for all active savers, referred to as `totalSaveDuration`. The user's saving time share relative to other savers' durations is calculated as:
`userTimeShare = (userSaveDuration / totalSaveDuration) * 100`

The average of these shares gives the user’s interest share based on the time saved and the amount saved, assuming they complete their saving period. If they don’t, they are charged a default fee that is added to the interest pool.

`averageShare = (userAmountShare + userTimeShare) / 2`
Thus, the `userInterestShare = (averageShare / 100) * interestPool`

User receives their interest share on completion of their saving duraion.

## Group Save

`Group Save` enables users to collectively save and manage their funds. This feature can be utilized by friends, social clubs, family finances, couples, business teams, and others. It not only allows users to save together but also provides a mechanism for managing how the group's tokens are spent through the use of `proposals` and `quorums`.

Each group, upon creation, includes `members` and a `quorum`. Any member can create a `proposal`, which specifies `recipients` and the `amounts` to be transferred from the group balance, with the option to include `multiple recipients` in a single proposal. These proposals are only approved when the group's quorum is reached. The quorum is the number of members needed for a proposal to pass or be rejected. Anyone can add funds to the group's balance. Additionally, each group has a `pendingAmount`, which accounts for amounts in active proposals that haven't been rejected. This pending amount is treated as if it has already been deducted from the group balance to prevent creating proposals that would exceed the available balance until those proposals are resolved.

An example of this would be setting up a group savings fund for an organization, with all executive members included in the group. Suppose the organization has several upcoming events, including a dinner, and they decide to cancel some of these events, such as the dinner. The president can propose allocating a portion of the group's funds to the dinner planner from the group savings. The other executive members then have the right to approve or reject this proposal. If the proposal reaches the required quorum for approval, the funds for the dinner will be transferred to the dinner planner and deducted from the group balance. However, if the proposal is rejected or fails to reach the necessary quorum due to insufficient member participation, the proposal will be declined, and the funds will remain in the group savings.

So Group savings can be applied in various other situations to facilitate fund management among different users and individuals.

# Target Driven Save

`Target-Driven Save` enable users to save with specific goals in mind, rather than saving aimlessly. This approach discourages flexibility that could lead to complacency, ensuring users stay committed to reaching their savings targets without dipping into their savings prematurely. Target-driven saving emphasizes setting goals based on amounts, timeframes, or a combination of both, with the flexibility to add to savings at any time.

`Time-targeted savings` allow users to save a specified amount of mtrg tokens over a set period, with restrictions on accessing these savings until the designated time period has elapsed. This method ensures a strict and secure way to reserve funds for a future purpose without the option to unlock them prematurely.
For instance, imagine someone is saving up for a newly announced laptop with a known price that they plan to purchase two months from now. If they already have part of the required funds and want to prevent spending them prematurely, they can initiate a time-targeted savings plan for exactly two months. During this period, they cannot access these savings until the two months have passed, ensuring the funds are reserved for the intended purchase without the risk of spending them beforehand. This method effectively helps users set aside money for future needs while maintaining disciplined saving habits.

`Amount-driven savings` enable users to define a starting savings amount and a target amount without attaching a specific timeframe. They can only access these savings once they consistently add to the initial amount until it reaches the set target. This method is beneficial for incremental saving towards a goal when the full amount isn't available immediately.
For example, suppose someone wants to buy a pet goldfish but doesn't have enough money upfront. They can set the target amount equal to the price of the goldfish and start with whatever funds they currently have. As they earn more through subsequent workdays, they continue adding to their savings until they reach the target amount required to purchase the goldfish. This approach ensures disciplined saving towards a specific goal, preventing premature spending and allowing funds to accumulate gradually until the goal is achieved.

`Mixed Target savings` offer a combination of both time-based and amount-based targets, requiring users to meet both conditions before they can access their savings. This means they must reach the specified savings target amount and also wait until the predetermined time period has elapsed before unlocking their funds.

Once users achieve their savings goal, they gain the ability to withdraw their target savings.

# Verified Deployed Contract Addresses

### Testnet

- Link to live demo [here](https://savesphere-git-main-franfran20s-projects.vercel.app/)
- Link to video demo [here](https://youtu.be/nOsmbu0j9P0)
- FlexSave - [0x9FAA0978666B45bACD623E1abD24EbC456bD018b](https://scan-warringstakes.meter.io/address/0x9faa0978666b45bacd623e1abd24ebc456bd018b)
- GroupSave - [0xca19D52603977Aff02E3dF9d6844ABDED270dDf4](https://scan-warringstakes.meter.io/address/0xca19D52603977Aff02E3dF9d6844ABDED270dDf4)
- TargetDrivenSave - [0x36f7c8875836f3C18d188Cb6AE7cFe253218EcA6](https://scan-warringstakes.meter.io/address/0x36f7c8875836f3C18d188Cb6AE7cFe253218EcA6)
