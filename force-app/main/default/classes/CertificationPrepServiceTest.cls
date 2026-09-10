/*
 * ============================================================================
 * CertificationPrepServiceTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 11 - Salesforce Certification Prep]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies CertificationPrepService logic:
 *   - Querying Certification_Question__c by topic / difficulty
 *   - Generating a randomly-selected practice/quiz session
 *   - Validating submitted answers against Correct_Answer__c
 *   - Question statistics by topic and difficulty
 *   - Creating a Certification_Study_Plan__c for a user
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. The question bank is a custom object; each row stores the question
 *    text, four answer options, the correct answer, and an explanation
 *    (so the app can score answers and show learning feedback).
 * 2. Test data for the question bank is built in @TestSetup so every
 *    test method starts from the same known 4-question set.
 * 3. Aggregate queries (GROUP BY Topic / Difficulty) power the stats.
 * 4. Map<String, List<String>> study topics and Map<String, Object> exam
 *    metadata show how loosely-typed maps feed UI views.
 * ============================================================================
 */
@isTest
private class CertificationPrepServiceTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Builds the adult-size question bank used by the tests:
     *   - Q1: Lead Management  (Easy)
     *   - Q2: Sales Analytics  (Medium)
     *   - Q3: Process Automation (Hard)
     *   - Q4: Account & Contact Mgmt (Easy)
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        List<Certification_Question__c> questions = new List<Certification_Question__c>();

        questions.add(new Certification_Question__c(
            Question_Text__c = 'What is the correct way to convert a lead?',
            Option_A__c = 'Click the Convert button on the lead record',
            Option_B__c = 'Use the Lead Conversion wizard',
            Option_C__c = 'Both A and B are correct',
            Option_D__c = 'Use the Lead Conversion API',
            Correct_Answer__c = 'C',
            Explanation__c = 'Both the Convert button and Lead Conversion wizard can be used.',
            Topic__c = 'Lead Management',
            Difficulty__c = 'Easy'
        ));

        questions.add(new Certification_Question__c(
            Question_Text__c = 'Which object stores information about sales targets?',
            Option_A__c = 'Opportunity',
            Option_B__c = 'Quota',
            Option_C__c = 'Forecast',
            Option_D__c = 'Target',
            Correct_Answer__c = 'B',
            Explanation__c = 'Quota objects store sales targets for users.',
            Topic__c = 'Sales Analytics',
            Difficulty__c = 'Medium'
        ));

        questions.add(new Certification_Question__c(
            Question_Text__c = 'What is the maximum number of approval steps in a process?',
            Option_A__c = '5',
            Option_B__c = '10',
            Option_C__c = '25',
            Option_D__c = 'No limit',
            Correct_Answer__c = 'D',
            Explanation__c = 'There is no limit on the number of approval steps.',
            Topic__c = 'Process Automation',
            Difficulty__c = 'Hard'
        ));

        questions.add(new Certification_Question__c(
            Question_Text__c = 'Which field type is best for storing currency values?',
            Option_A__c = 'Number',
            Option_B__c = 'Currency',
            Option_C__c = 'Text',
            Option_D__c = 'Percent',
            Correct_Answer__c = 'B',
            Explanation__c = 'Currency field type is designed for monetary values.',
            Topic__c = 'Account & Contact Management',
            Difficulty__c = 'Easy'
        ));

        insert questions;
    }

    // ------------------------------------------------------------------------
    // QUERYING THE QUESTION BANK.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetQuestionsByTopic() {
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsByTopic('Lead Management');

        System.assertEquals(1, questions.size(),
            'Should return 1 Lead Management question');
        System.assertEquals('Lead Management', questions[0].Topic__c);
    }

    @isTest
    static void testGetQuestionsByDifficulty() {
        // Two questions have Difficulty__c = 'Easy' (Q1, Q4)
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsByDifficulty('Easy');

        System.assertEquals(2, questions.size(),
            'Should return 2 Easy questions');
    }

    @isTest
    static void testGetQuestionsByTopicAndDifficulty() {
        // Combined filter: topic + difficulty
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsByTopicAndDifficulty(
                'Sales Analytics', 'Medium'
            );

        System.assertEquals(1, questions.size(),
            'Should return 1 Medium Sales Analytics question');
    }

    @isTest
    static void testGetQuestionsForPractice() {
        // Practice mode returns a capped, randomly-ordered set
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsForPractice(10);

        System.assert(questions.size() <= 10,
            'Should return up to 10 questions');
    }

    // ------------------------------------------------------------------------
    // STATS - aggregate counts to power the "your readiness" charts.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetQuestionStats() {
        Map<String, Integer> stats = CertificationPrepService.getQuestionStats();

        System.assert(stats.containsKey('Lead Management'),
            'Should have Lead Management stats');
        System.assert(stats.containsKey('Sales Analytics'),
            'Should have Sales Analytics stats');
        System.assertEquals(1, stats.get('Lead Management'));
    }

    @isTest
    static void testGetDifficultyStats() {
        Map<String, Integer> stats = CertificationPrepService.getDifficultyStats();

        System.assert(stats.containsKey('Easy'), 'Should have Easy stats');
        System.assert(stats.containsKey('Medium'), 'Should have Medium stats');
        System.assert(stats.containsKey('Hard'), 'Should have Hard stats');
    }

    // ------------------------------------------------------------------------
    // STUDY GUIDANCE - static study topics and exam metadata.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetStudyTopics() {
        Map<String, List<String>> topics = CertificationPrepService.getStudyTopics();

        System.assert(topics.containsKey('Lead Management'),
            'Should have Lead Management topics');
        System.assert(topics.containsKey('Opportunity Management'),
            'Should have Opportunity Management topics');
        System.assert(!topics.get('Lead Management').isEmpty(),
            'Lead Management should have subtopics');
    }

    @isTest
    static void testGetExamTips() {
        // Example exam blueprint for the Salesforce Admin cert
        Map<String, Object> tips = CertificationPrepService.getExamTips('Admin');

        System.assertEquals(60, tips.get('totalQuestions'));
        System.assertEquals(65, tips.get('passingScore'));
        System.assertEquals(90, tips.get('timeLimit'));
        System.assert(tips.containsKey('keyAreas'));
        System.assert(tips.containsKey('studyTips'));
    }

    // ------------------------------------------------------------------------
    // STUDY PLAN - DML on the study-plan custom object.
    // ------------------------------------------------------------------------

    @isTest
    static void testCreateStudyPlan() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Certification_Study_Plan__c plan = CertificationPrepService.createStudyPlan(
            testUser.Id,
            'Salesforce Administrator',
            Date.today().addDays(30)
        );

        System.assertNotEquals(null, plan.Id, 'Study plan should be created');
        System.assertEquals('Salesforce Administrator', plan.Certification_Type__c);
        System.assertEquals('In Progress', plan.Status__c);
    }

    // ------------------------------------------------------------------------
    // QUIZ ENGINE - question payloads for the quiz UI + answer grading.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetQuizQuestions() {
        List<Map<String, Object>> quiz = CertificationPrepService.getQuizQuestions(2);

        System.assertEquals(2, quiz.size(), 'Should return 2 quiz questions');

        for (Map<String, Object> q : quiz) {
            System.assert(q.containsKey('id'), 'Question should have id');
            System.assert(q.containsKey('question'), 'Question should have text');
            System.assert(q.containsKey('options'), 'Question should have options');
            System.assert(q.containsKey('topic'), 'Question should have topic');
        }
    }

    @isTest
    static void testValidateAnswerCorrect() {
        Certification_Question__c question = [
            SELECT Id, Correct_Answer__c FROM Certification_Question__c
            WHERE Correct_Answer__c = 'C' LIMIT 1
        ];

        Map<String, Object> result = CertificationPrepService.validateAnswer(
            question.Id, 'C'
        );

        System.assertEquals(true, result.get('correct'),
            'Answer C should be correct');
        System.assertEquals('C', result.get('correctAnswer'));
    }

    @isTest
    static void testValidateAnswerIncorrect() {
        Certification_Question__c question = [
            SELECT Id, Correct_Answer__c FROM Certification_Question__c
            WHERE Correct_Answer__c = 'C' LIMIT 1
        ];

        Map<String, Object> result = CertificationPrepService.validateAnswer(
            question.Id, 'A'
        );

        System.assertEquals(false, result.get('correct'),
            'Answer A should be incorrect');
        System.assertEquals('C', result.get('correctAnswer'));
    }

    // ------------------------------------------------------------------------
    // EDGE CASES - unknown topics and zero limits must not crash.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetQuestionsByTopicEmpty() {
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsByTopic('Nonexistent Topic');

        System.assert(questions.isEmpty(),
            'Should return empty list for nonexistent topic');
    }

    @isTest
    static void testGetQuestionsForPracticeZero() {
        List<Certification_Question__c> questions =
            CertificationPrepService.getQuestionsForPractice(0);

        System.assert(questions.isEmpty(),
            'Should return empty list when limit is 0');
    }
}