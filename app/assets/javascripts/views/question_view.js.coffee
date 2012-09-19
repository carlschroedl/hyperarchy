class Views.QuestionView extends View
  @content: ->
    @div class: 'question', =>
      @div class: 'row header', =>
        @div class: 'span8', =>
          @div class: 'body lead', outlet: 'body'
        @div class: 'span4', =>
          @button class: 'delete btn btn-link pull-right', outlet: 'deleteButton', click: 'deleteQuestion', =>
            @i class: 'icon-trash'
            @span "Delete"

          @button class: 'edit-body btn btn-link pull-right', outlet: 'editButton', click: 'editQuestionBody', =>
            @i class: 'icon-edit'
            @span "Edit"

      @div class: 'row', =>
        @div class: 'span4', =>
          @h5 =>
            @a "Collective Ranking", class: 'no-href disabled', click: 'showCollectiveVote', outlet: 'showCollectiveVoteLink'
            @span "|", class: 'separator'
            @a "Individual Rankings", class: 'no-href', click: 'showAllVotes', outlet: 'showAllVotesLink'

          @subview 'collectiveVote', new Views.RelationView(
            attributes: { class: 'collective vote column' }
          )

          @subview 'allVotes', new Views.RelationView(
            attributes: { class: 'all-votes column hide' }
            buildItem: (vote) -> new Views.VoteView(vote)
          )

        @div class: 'span4', =>
          @h5 =>
            @button "+ Add Answer", class: 'btn btn-small btn-primary add-answer pull-right', click: 'addAnswer'
            @text "Your Ranking"

          @subview 'personalVote', new Views.RelationView(
            attributes: { class: 'personal vote column' }
          )

        @div class: 'span4', =>
          @h5 'Discussion'
          @div class: 'discussion column', =>
            @subview 'comments', new Views.RelationView(
              buildItem: (comment) -> new Views.CommentItem(comment)
            )
            @div class: 'text-entry', =>
              @textarea rows: 2, outlet: 'commentTextarea'
              @button "Submit Comment", class: 'btn pull-right', click: 'createComment'

  initialize: (@question) ->
    @rankedItemsByAnswerId = {}
    @body.text(question.body())

    @collectiveVote.buildItem = (answer) => @buildAnswerItem(answer, draggable: true)
    @collectiveVote.setRelation(question.answers())

    @personalVote.buildItem = (ranking) =>
      @buildAnswerItem(ranking.answer(), position: ranking.position())
    @personalVote.onInsert = (item, ranking) =>
      @rankedItemsByAnswerId[ranking.answerId()]?.remove()
      @rankedItemsByAnswerId[ranking.answerId()] = item
    @personalVote.setRelation(Models.User.getCurrent().rankingsForQuestion(question))

    removeItem = null
    @personalVote.sortable(
      receive: -> removeItem = 0
      over: -> removeItem = 0
      out: -> removeItem = 1
      beforeStop: (event, ui) -> ui.item.detach() if removeItem
      stop: (event, ui) => @updateAnswerRanking(ui.item)
    )

    @allVotes.setRelation(@question.votes())

    @comments.setRelation(@question.comments())

    unless @question.creator() == Models.User.getCurrent()
      @editButton.hide()
      @deleteButton.hide()

    question.getField('body').onChange (body) =>
      @body.text(body)

  buildAnswerItem: (answer, options) ->
    new Views.AnswerItem(answer, options)

  showCollectiveVote: ->
    @enableLink(@showAllVotesLink)
    @disableLink(@showCollectiveVoteLink)
    @allVotes.hide()
    @collectiveVote.show()

  showAllVotes: ->
    @enableLink(@showCollectiveVoteLink)
    @disableLink(@showAllVotesLink)
    @collectiveVote.hide()
    @allVotes.show()

  enableLink: (link) ->
    link.removeClass('disabled')

  disableLink: (link) ->
    link.addClass('disabled')

  updateAnswerRanking: (item) ->
    answerId = item.data('answer-id')
    answer = Models.Answer.find(answerId)

    unless item.parent().length
      Models.Ranking.destroyByAnswerId(answerId)
        .done => @highlightAnswerInCollectiveRanking(answer, true)
      delete @rankedItemsByAnswerId[answerId]
      item.remove()
      return

    existingItem = @rankedItemsByAnswerId[answerId]
    if existingItem and existingItem[0] != item[0]
      item.replaceWith(existingItem.detach())
      item = existingItem
    @rankedItemsByAnswerId[answerId] = item

    lowerPosition = item.next()?.data('position') ? 0
    if item.prev().length
      upperPosition = item.prev().data('position')
      position = (upperPosition + lowerPosition) / 2
    else
      position = lowerPosition + 1

    item.data('position', position)
    item.text(item.text().replace('undefined', position))

    Models.Ranking.createOrUpdate(
      answer: answer
      position: position
    )
      .done =>
        @highlightAnswerInCollectiveRanking(answer, true)

  addAnswer: ->
    new Views.ModalForm(
      headingText: @question.body()
      buttonText: "Add Answer"
      onSubmit: (body) =>
        @question.answers().create({body})
    )

  editQuestionBody: ->
    new Views.ModalForm(
      text: @question.body()
      headingText: 'Edit your question:'
      buttonText: "Save Changes"
      onSubmit: (body) =>
        @question.update({body})
    )

  createComment: ->
    body = @commentTextarea.val()
    if /\S/.test(body)
      @question.comments().create({body})

  deleteQuestion: ->
    if confirm("Are you sure you want to delete this question?")
      @question.destroy()

  highlightAnswerInCollectiveRanking: (answer, delay) ->
    if delay
      subscription = @question.onUpdate =>
        subscription.destroy()
        fn = => @highlightAnswerInCollectiveRanking(answer)
        _.delay(fn, 30)
      return

    item = @collectiveVote.find(".answer[data-answer-id=#{answer.id()}]")

    if item.position().top < 0 or item.position().top > @collectiveVote.height()
      @collectiveVote.scrollTo(item, over: -.5)
    item.effect('highlight')

  remove: (selector, keepData) ->
    super
    unless keepData
      @collectiveVote.remove()
      @personalVote.remove()
      @allVotes.remove()
