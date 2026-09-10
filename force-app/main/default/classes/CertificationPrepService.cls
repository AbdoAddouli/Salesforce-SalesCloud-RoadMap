/*
 * ============================================================================
 * CertificationPrepService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 11 - Certification Prep]
 *
 * WHAT THIS CLASS DOES:
 * Powers the practice-quiz and study-plan features of the learning project.
 * Reads from the custom object Certification_Question__c (practice exam
 * questions) and Certification_Study_Plan__c (user study targets).
 *
 * RESPONSIBILITIES:
 *   - Retrieve questions by topic / difficulty / count
 *   - Return question statistics (grouped by topic, by difficulty)
 *   - Serve static "study topic" and "exam tips" content
 *   - Create study plans for users
 *   - Produce a quiz (list of maps) and validate answers
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. ORDER BY RANDOM() - SOQL can randomize result order (handy for quizzes).
 * 2. Returning `Map<String, Object>` / `List<Map<String, Object>>` - flexible
 *    structures ideal for feeding a Lightning Web Component or Visualforce.
 * 3. Maps used to return loosely-typed, self-describing results.
 * ============================================================================
 */
public with sharing class CertificationPrepService {

    /*
     * getQuestionsByTopic(String topic)
     * ----------------------------------------------------------------------
     * PURPOSE: Pull all practice questions for a given topic in random order.
     * ----------------------------------------------------------------------
     */
    public static List<Certification_Question__c> getQuestionsByTopic(String topic) {
        return [
            SELECT Id, Question_Text__c, Option_A__c, Option_B__c,
                   Option_C__c, Option_D__c, Explanation__c,
                   Difficulty__c, Topic__c
            FROM Certification_Question__c
            WHERE Topic__c = :topic
            ORDER BY RANDOM()
        ];
    }

    /*
     * getQuestionsByDifficulty(String difficulty)
     * ----------------------------------------------------------------------
     * PURPOSE: Pull questions matching a difficulty level (Easy/Medium/Hard).
     * ----------------------------------------------------------------------
     */
    public static List<Certification_Question__c> getQuestionsByDifficulty(String difficulty) {
        return [
            SELECT Id, Question_Text__c, Option_A__c, Option_B__c,
                   Option_C__c, Option_D__c, Explanation__c,
                   Difficulty__c, Topic__c
            FROM Certification_Question__c
            WHERE Difficulty__c = :difficulty
            ORDER BY RANDOM()
        ];
    }

    /*
     * getQuestionsByTopicAndDifficulty(String topic, String difficulty)
     * ----------------------------------------------------------------------
     * PURPOSE: Filter by BOTH criteria (AND in the WHERE clause). Lets a
     * student study, say, only "Hard" "Opportunity Management" questions.
     * ----------------------------------------------------------------------
     */
    public static List<Certification_Question__c> getQuestionsByTopicAndDifficulty(
        String topic, String difficulty
    ) {
        return [
            SELECT Id, Question_Text__c, Option_A__c, Option_B__c,
                   Option_C__c, Option_D__c, Explanation__c,
                   Difficulty__c, Topic__c
            FROM Certification_Question__c
            WHERE Topic__c = :topic AND Difficulty__c = :difficulty
            ORDER BY RANDOM()
        ];
    }

    /*
     * getQuestionsForPractice(Integer limit_count)
     * ----------------------------------------------------------------------
     * PURPOSE: Pull up to N random questions (a random practice set).
     * Uses ORDER BY RANDOM() + LIMIT together.
     * ----------------------------------------------------------------------
     */
    public static List<Certification_Question__c> getQuestionsForPractice(Integer limit_count) {
        return [
            SELECT Id, Question_Text__c, Option_A__c, Option_B__c,
                   Option_C__c, Option_D__c, Explanation__c,
                   Difficulty__c, Topic__c
            FROM Certification_Question__c
            ORDER BY RANDOM()
            LIMIT :limit_count
        ];
    }

    /*
     * getQuestionStats()
     * ----------------------------------------------------------------------
     * PURPOSE: Count questions per TOPIC. Good for showing a student where
     * they have the most/least coverage.
     *
     * KEY: AggregateResult with GROUP BY Topic__c.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Integer> getQuestionStats() {
        Map<String, Integer> stats = new Map<String, Integer>();

        List<AggregateResult> topicResults = [
            SELECT Topic__c, COUNT(Id) cnt
            FROM Certification_Question__c
            GROUP BY Topic__c
        ];

        for (AggregateResult ar : topicResults) {
            stats.put((String) ar.get('Topic__c'), (Integer) ar.get('cnt'));
        }

        return stats;
    }

    /*
     * getDifficultyStats()
     * ----------------------------------------------------------------------
     * PURPOSE: Count questions per DIFFICULTY level (Easy/Medium/Hard).
     * ----------------------------------------------------------------------
     */
    public static Map<String, Integer> getDifficultyStats() {
        Map<String, Integer> stats = new Map<String, Integer>();

        List<AggregateResult> results = [
            SELECT Difficulty__c, COUNT(Id) cnt
            FROM Certification_Question__c
            GROUP BY Difficulty__c
        ];

        for (AggregateResult ar : results) {
            stats.put((String) ar.get('Difficulty__c'), (Integer) ar.get('cnt'));
        }

        return stats;
    }

    /*
     * getStudyTopics()
     * ----------------------------------------------------------------------
     * PURPOSE: Serve the curated list of exam study topics & subtopics.
     * This is STATIC content (no SOQL) - a simple Map<String, List<String>>.
     * ----------------------------------------------------------------------
     */
    public static Map<String, List<String>> getStudyTopics() {
        Map<String, List<String>> topics = new Map<String, List<String>>();

        topics.put('Lead Management', new List<String>{
            'Lead conversion process',
            'Lead assignment rules',
            'Lead scoring',
            'Lead nurturing',
            'Web-to-Lead'
        });

        topics.put('Account & Contact Management', new List<String>{
            'Account hierarchy',
            'Contact roles',
            'Account teams',
            'Territory management',
            'Duplicate management'
        });

        topics.put('Opportunity Management', new List<String>{
            'Opportunity stages',
            'Products and price books',
            'Quotes',
            'Opportunity teams',
            'Collaborative forecasting'
        });

        topics.put('Sales Analytics', new List<String>{
            'Reports and dashboards',
            'Key metrics',
            'Pipeline analysis',
            'Win rate analysis',
            'Forecasting'
        });

        topics.put('Process Automation', new List<String>{
            'Workflow rules',
            'Process Builder',
            'Flow Builder',
            'Validation rules',
            'Approval processes'
        });

        topics.put('Sales Collaboration', new List<String>{
            'Chatter',
            'Activities',
            'Mobile app',
            'Email integration',
            'Collaborative forecasting'
        });

        return topics;
    }

    /*
     * getExamTips(String certificationType)
     * ----------------------------------------------------------------------
     * PURPOSE: Return generic exam structure & study tips. In a fuller app,
     * the tips could vary by `certificationType`; here it returns static data.
     * Notice the mixed-type values -> Map<String, Object> is required because
     * values can be Integer or List<String>.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Object> getExamTips(String certificationType) {
        Map<String, Object> tips = new Map<String, Object>();

        tips.put('totalQuestions', 60);
        tips.put('passingScore', 65);
        tips.put('timeLimit', 90);
        tips.put('questionTypes', new List<String>{
            'Multiple choice',
            'True/False',
            'Scenario-based'
        });

        tips.put('keyAreas', new List<String>{
            'Configuration (20%)',
            'Setup (15%)',
            'Objects and Fields (13%)',
            'Security (12%)',
            'Reports and Dashboards (10%)',
            'Activities (8%)',
            'Chatter (7%)',
            'Other (15%)'
        });

        tips.put('studyTips', new List<String>{
            'Focus on hands-on practice',
            'Understand business scenarios',
            'Know the difference between similar features',
            'Practice time management',
            'Review release notes for new features'
        });

        return tips;
    }

    /*
     * createStudyPlan(Id userId, String certificationType, Date targetDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Create a Certification_Study_Plan__c record (a goal) for a
     * user. The record starts with Status = 'In Progress'.
     *
     * NOTE: Since this method performs DML (insert), it is designed to be
     * called from a UI/Lightning action - NOT from within a trigger.
     * ----------------------------------------------------------------------
     */
    public static Certification_Study_Plan__c createStudyPlan(
        Id userId, String certificationType, Date targetDate
    ) {
        Certification_Study_Plan__c plan = new Certification_Study_Plan__c(
            User__c = userId,
            Certification_Type__c = certificationType,
            Target_Date__c = targetDate,
            Status__c = 'In Progress'
        );

        insert plan;
        return plan;
    }

    /*
     * getQuizQuestions(Integer questionCount)
     * ----------------------------------------------------------------------
     * PURPOSE: Build a quiz as a List of Maps (one per question), ideal for
     * serializing to JSON for a Lightning Web Component. Reuses
     * getQuestionsForPractice() for the random selection, then drops the
     * "correct answer" out of the payload (so the answer isn't visible
     * client-side until submitted).
     * ----------------------------------------------------------------------
     */
    public static List<Map<String, Object>> getQuizQuestions(Integer questionCount) {
        List<Certification_Question__c> questions = getQuestionsForPractice(questionCount);

        List<Map<String, Object>> quiz = new List<Map<String, Object>>();

        for (Certification_Question__c q : questions) {
            quiz.add(new Map<String, Object>{
                'id' => q.Id,
                'question' => q.Question_Text__c,
                'options' => new Map<String, String>{
                    'A' => q.Option_A__c,
                    'B' => q.Option_B__c,
                    'C' => q.Option_C__c,
                    'D' => q.Option_D__c
                },
                'topic' => q.Topic__c,
                'difficulty' => q.Difficulty__c
            });
        }

        return quiz;
    }

    /*
     * validateAnswer(Id questionId, String userAnswer)
     * ----------------------------------------------------------------------
     * PURPOSE: Check a user's submitted answer (A/B/C/D) against the stored
     * correct answer. Returns the verdict + the explanation.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Object> validateAnswer(Id questionId, String userAnswer) {
        Certification_Question__c question = [
            SELECT Correct_Answer__c, Explanation__c, Topic__c
            FROM Certification_Question__c
            WHERE Id = :questionId
        ];

        Boolean isCorrect = question.Correct_Answer__c == userAnswer;

        return new Map<String, Object>{
            'correct' => isCorrect,
            'correctAnswer' => question.Correct_Answer__c,
            'explanation' => question.Explanation__c,
            'topic' => question.Topic__c
        };
    }
}