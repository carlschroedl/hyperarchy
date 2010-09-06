_.constructor("Views.RankedCandidateLi", Views.CandidateLi, {
  content: function($super, params) {
    if (!params.candidate) params.candidate = params.ranking.candidate();
    $super(params);
  },

  additionalClass: "ranked",

  candidateIcon: function() { with(this.builder) {
    div({'class': "candidateIcon loading", style: "display: none;"}).ref('loadingIcon');
    div({'class': "candidateIcon unrankCandidate", style: "display: none;"})
      .ref('destroyRankingButton')
      .click('destroyRanking');
  }},

  viewProperties: {
    initialize: function() {
      if (!this.candidate) this.candidate = this.ranking.candidate();
      if (!this.ranking) this.ranking = this.candidate.rankingByCurrentUser().first();
    },

    startLoading: function() {
      this.loadingIcon.show();
      this.destroyRankingButton.hide();
    },

    stopLoading: function() {
      this.loadingIcon.hide();
      this.destroyRankingButton.show();
    },

    destroyRanking: function() {
      this.startLoading();
      this.ranking.destroy();
    }
  }
});