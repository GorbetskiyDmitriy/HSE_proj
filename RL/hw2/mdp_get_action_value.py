def get_action_value(mdp, state_values, state, action, gamma):
    """ Computes Q(s,a) as in formula above """

    # YOUR CODE HERE
    Q = 0
    for s in state_values:
        P = mdp.get_transition_prob(state, action, s)
        r = mdp.get_reward(state, action, s)
        V_gamma = gamma * state_values[s]
        Q += P * (r + V_gamma)
    return Q
