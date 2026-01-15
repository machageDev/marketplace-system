from typing import List, Dict, Any
import re

class SimpleJobMatcher:
    """
    SIMPLE job matcher that actually works with real data.
    Based on logs: Freelancer skills = "hacker", need to match with available tasks.
    """
    
    @staticmethod
    def normalize_skill(skill: str) -> str:
        """Normalize a single skill string."""
        if not skill:
            return ""
        return skill.strip().lower()
    
    @staticmethod
    def extract_skills(skills_input) -> List[str]:
        """Extract skills from any input format."""
        if not skills_input:
            return []
        
        skills_list = []
        
        if isinstance(skills_input, str):
            # Split by comma, semicolon, or space
            parts = re.split(r'[,\s;]+', skills_input)
            skills_list = [SimpleJobMatcher.normalize_skill(p) for p in parts if p.strip()]
        elif isinstance(skills_input, list):
            skills_list = [SimpleJobMatcher.normalize_skill(str(s)) for s in skills_input if s]
        
        return skills_list
    
    @staticmethod
    def skill_similarity(skill1: str, skill2: str) -> float:
        """Check if two skills are similar."""
        if not skill1 or not skill2:
            return 0.0
        
        skill1 = skill1.lower()
        skill2 = skill2.lower()
        
        # Exact match
        if skill1 == skill2:
            return 1.0
        
        # Contains match
        if skill1 in skill2 or skill2 in skill1:
            return 0.8
        
        # Common skill mappings (based on actual freelance work)
        skill_groups = {
            'hacker': ['programmer', 'coder', 'developer', 'programming', 'coding'],
            'programmer': ['coder', 'developer', 'hacker', 'software'],
            'coder': ['programmer', 'developer', 'hacker'],
            'developer': ['programmer', 'coder', 'engineer'],
            'web': ['website', 'internet', 'online'],
            'design': ['graphic', 'ui', 'ux', 'creative'],
            'cleaning': ['housekeeping', 'janitor', 'clean'],
            'marketing': ['promotion', 'advertising', 'seo'],
            'writing': ['content', 'copywriting', 'blog'],
        }
        
        # Check if skills are in same group
        for group, related_skills in skill_groups.items():
            if skill1 in related_skills and skill2 in related_skills:
                return 0.7
            if skill1 == group and skill2 in related_skills:
                return 0.7
            if skill2 == group and skill1 in related_skills:
                return 0.7
        
        return 0.0
    
    @staticmethod
    def calculate_match(freelancer_skills: List[str], job_skills: List[str]) -> Dict[str, Any]:
        """Calculate match between freelancer and job skills."""
        if not job_skills:
            return {"score": 0, "matches": [], "overlap": 0}
        
        matches = []
        match_score = 0
        
        for f_skill in freelancer_skills:
            for j_skill in job_skills:
                similarity = SimpleJobMatcher.skill_similarity(f_skill, j_skill)
                if similarity > 0.6:  # Good enough match
                    matches.append({
                        "freelancer_skill": f_skill,
                        "job_skill": j_skill,
                        "similarity": similarity
                    })
                    match_score += similarity * 25  # 25 points per good match
        
        # Cap score at 100
        match_score = min(100, match_score)
        
        # Give base score even for partial matches
        if match_score == 0 and freelancer_skills and job_skills:
            match_score = 10  # Minimum score if there are any skills
        
        return {
            "score": round(match_score, 2),
            "matches": matches,
            "overlap": len(matches)
        }
    
    @staticmethod
    def text_similarity(text1: str, text2: str) -> float:
        """Simple text similarity based on common words."""
        if not text1 or not text2:
            return 0.0
        
        # Clean texts
        text1 = re.sub(r'[^\w\s]', ' ', text1.lower())
        text2 = re.sub(r'[^\w\s]', ' ', text2.lower())
        
        words1 = set(text1.split())
        words2 = set(text2.split())
        
        if not words1 or not words2:
            return 0.0
        
        common_words = words1.intersection(words2)
        similarity = len(common_words) / max(len(words1), len(words2))
        
        return similarity
    
    @staticmethod
    def rank_jobs_for_freelancer(freelancer_profile, jobs: List, top_n: int = 20) -> List[Dict[str, Any]]:
        """
        Rank jobs for a freelancer based on SIMPLE skill matching.
        Returns ALL jobs with match scores.
        """
        if not jobs:
            return []
        
        print(f"\n=== SIMPLE MATCHER: Ranking {len(jobs)} jobs ===")
        print(f"Freelancer skills: '{freelancer_profile.skills}'")
        
        # Extract freelancer skills
        freelancer_skills = SimpleJobMatcher.extract_skills(freelancer_profile.skills)
        print(f"Extracted freelancer skills: {freelancer_skills}")
        
        # Get freelancer bio/text for text matching
        freelancer_text = ""
        if hasattr(freelancer_profile, 'bio') and freelancer_profile.bio:
            freelancer_text = freelancer_profile.bio.lower()
        if hasattr(freelancer_profile, 'experience') and freelancer_profile.experience:
            freelancer_text += " " + freelancer_profile.experience.lower()
        
        results = []
        
        for job in jobs:
            # Extract job skills
            job_skills = SimpleJobMatcher.extract_skills(job.required_skills)
            
            # Calculate skill match
            skill_match = SimpleJobMatcher.calculate_match(freelancer_skills, job_skills)
            
            # Calculate text similarity
            job_text = ""
            if hasattr(job, 'title'):
                job_text = job.title.lower()
            if hasattr(job, 'description'):
                job_text += " " + job.description.lower()
            
            text_similarity_score = SimpleJobMatcher.text_similarity(freelancer_text, job_text)
            text_bonus = text_similarity_score * 30  # Max 30 points for text
            
            # Calculate category bonus (if job has category)
            category_bonus = 0
            if hasattr(job, 'category') and job.category:
                # Simple category matching
                job_category = job.category.lower()
                freelancer_categories = [s for s in freelancer_skills if len(s) > 3]
                
                for cat in freelancer_categories:
                    if cat in job_category or job_category in cat:
                        category_bonus = 20
                        break
            
            # Final score
            final_score = skill_match["score"] + text_bonus + category_bonus
            final_score = min(100, max(10, final_score))  # Ensure 10-100 range
            
            # Get common exact skills
            common_exact = []
            for f_skill in freelancer_skills:
                for j_skill in job_skills:
                    if f_skill == j_skill:
                        common_exact.append(f_skill)
            
            results.append({
                "job_id": job.task_id if hasattr(job, 'task_id') else getattr(job, 'id', 0),
                "score": round(final_score, 2),
                "skill_score": skill_match["score"],
                "text_bonus": round(text_bonus, 2),
                "category_bonus": category_bonus,
                "skill_overlap": skill_match["overlap"],
                "common_skills": common_exact,
                "all_freelancer_skills": freelancer_skills,
                "all_job_skills": job_skills,
                "job_title": job.title if hasattr(job, 'title') else "Unknown",
                "job_category": job.category if hasattr(job, 'category') else "",
            })
        
        # Sort by score
        results.sort(key=lambda x: x["score"], reverse=True)
        
        # Debug output
        print(f"\nTop 5 matches:")
        for i, res in enumerate(results[:5]):
            print(f"  {i+1}. '{res['job_title']}' - Score: {res['score']}%")
            print(f"     Skills: {res['all_job_skills']}")
            print(f"     Common: {res['common_skills']}")
        
        print(f"\nBottom 5 matches:")
        for i, res in enumerate(results[-5:] if len(results) >= 5 else results):
            print(f"  {i+1}. '{res['job_title']}' - Score: {res['score']}%")
        
        return results[:top_n]
    
    @staticmethod
    def rank_freelancers_for_job(job, freelancers: List, top_n: int = 10) -> List[Dict[str, Any]]:
        """Rank freelancers for a specific job."""
        if not freelancers:
            return []
        
        # Extract job skills
        job_skills = SimpleJobMatcher.extract_skills(
            job.required_skills if hasattr(job, 'required_skills') else None
        )
        
        results = []
        
        for freelancer in freelancers:
            # Extract freelancer skills
            freelancer_skills = SimpleJobMatcher.extract_skills(
                freelancer.skills if hasattr(freelancer, 'skills') else None
            )
            
            # Calculate match
            skill_match = SimpleJobMatcher.calculate_match(freelancer_skills, job_skills)
            
            # Add some base score
            base_score = max(10, skill_match["score"])
            
            results.append({
                "profile_id": freelancer.profile_id if hasattr(freelancer, 'profile_id') else getattr(freelancer, 'id', 0),
                "score": round(base_score, 2),
                "skill_overlap": skill_match["overlap"],
                "common_skills": [m["job_skill"] for m in skill_match["matches"]],
                "freelancer_skills": freelancer_skills,
            })
        
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_n]


# For backward compatibility
def rank_jobs_for_freelancer(freelancer, jobs, top_n=10) -> List[Dict[str, Any]]:
    """Wrapper for the simple matcher."""
    return SimpleJobMatcher.rank_jobs_for_freelancer(freelancer, jobs, top_n)

def rank_freelancers_for_job(job, freelancers, top_n=10) -> List[Dict[str, Any]]:
    """Wrapper for the simple matcher."""
    return SimpleJobMatcher.rank_freelancers_for_job(job, freelancers, top_n)


# Helper function for job text (backward compatibility)
def job_text(job) -> str:
    """Convert job to text (for backward compatibility)."""
    skills_text = ""
    if hasattr(job, "required_skills") and job.required_skills:
        skills_text = SimpleJobMatcher.extract_skills(job.required_skills)
        skills_text = " ".join(skills_text)
    
    return " ".join([
        job.title or "",
        job.description or "",
        skills_text
    ]).lower()


# Helper function for freelancer text (backward compatibility)
def freelancer_text(freelancer) -> str:
    """Convert freelancer to text (for backward compatibility)."""
    skills_text = ""
    if freelancer.skills:
        skills_text = SimpleJobMatcher.extract_skills(freelancer.skills)
        skills_text = " ".join(skills_text)
    
    return " ".join([
        freelancer.bio or "",
        skills_text,
        freelancer.experience or ""
    ]).lower()