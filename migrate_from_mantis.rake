# encoding: UTF-8
# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

desc 'Mantis migration script'

require 'active_record'
require 'iconv'
require 'pp'
require 'debugger'

namespace :redmine do
task :migrate_from_mantis => :environment do

  module MantisMigrate

      # Modified
      #DEFAULT_STATUS = IssueStatus.default
      #assigned_status = IssueStatus.find_by_position(2)
      #resolved_status = IssueStatus.find_by_position(3)
      #feedback_status = IssueStatus.find_by_position(4)
      #closed_status = IssueStatus.find :first, :conditions => { :is_closed => true }
      #STATUS_MAPPING = {10 => DEFAULT_STATUS, # new
      #                  20 => feedback_status, # feedback
      #                  30 => DEFAULT_STATUS, # acknowledged
      #                  40 => DEFAULT_STATUS, # confirmed
      #                  50 => assigned_status, # assigned
      #                  80 => resolved_status, # resolved
      #                  90 => closed_status # closed
      #                  }
      DEFAULT_STATUS = IssueStatus.default
      feedback_status = IssueStatus.find_by_position(2)
      acknowledged_status = IssueStatus.find_by_position(3)
      confirmed_status = IssueStatus.find_by_position(4)
      developer_status = IssueStatus.find_by_position(5)
      assigned_status = IssueStatus.find_by_position(6)
      corrected_status = IssueStatus.find_by_position(7)
      tested_status = IssueStatus.find_by_position(8)
      validated_status = IssueStatus.find_by_position(9)
      interrupted_status = IssueStatus.find_by_position(12)
      aguardando_status = IssueStatus.find_by_position(13)
      resolved_status = IssueStatus.find_by_position(10)
      closed_status = IssueStatus.find_by_position(11)
      STATUS_MAPPING = {10 => DEFAULT_STATUS,  	   # new
                        20 => feedback_status, 	   # feedback
                        30 => acknowledged_status, # acknowledged
                        40 => confirmed_status,	   # confirmed
                        45 => developer_status,	   # developer
                        50 => assigned_status, 	   # assigned
                        60 => corrected_status,	   # corrected
                        61 => tested_status,   	   # tested
                        62 => validated_status,	   # validated
                        63 => interrupted_status,  # interrupted
                        64 => aguardando_status,   # aguardando
                        80 => resolved_status, 	   # resolved
                        90 => closed_status    	   # closed
                        }

      # Priority modified
      #DEFAULT_PRIORITY = priorities[2]
      #PRIORITY_MAPPING = {10 => priorities[1], # none
      #                    20 => priorities[1], # low
      #                    30 => priorities[2], # normal
      #                    40 => priorities[3], # high
      #                    50 => priorities[4], # urgent
      #                    60 => priorities[5]  # immediate
      priorities = IssuePriority.all
      DEFAULT_PRIORITY = priorities[1]
      PRIORITY_MAPPING = {10 => priorities[0], # none
                          20 => priorities[0], # low
                          30 => priorities[1], # normal
                          40 => priorities[2], # high
                          50 => priorities[3], # urgent
                          60 => priorities[4]  # immediate
                          }

      # Modified Tracker
      #TRACKER_FUNCIONALIDADE = Tracker.find_by_position(1)
      #TRACKER_BUG = Tracker.find_by_position(2)
      corretiva_bug = Tracker.find_by_position(2)
      especfunc_bug = Tracker.find_by_position(17)
      funcionalidade_bug = Tracker.find_by_position(1)
      servico_bug = Tracker.find_by_position(7)
      adaptativa_bug = Tracker.find_by_position(3)
      nc_bug = Tracker.find_by_position(6)
      perfectiva_bug = Tracker.find_by_position(5)
      preventiva_bug = Tracker.find_by_position(4)
      estudo_bug = Tracker.find_by_position(8)
      statusreport_bug = Tracker.find_by_position(9)
      processo_bug = Tracker.find_by_position(14)
      DEFAULT_TRACKER = Tracker.find_by_position(12)
      TRACKER_MAPPING = {'Corretiva' => corretiva_bug,         #corretiva
                         'Especificação Funcional' => especfunc_bug, #especificação funcional
                         'Nova Função' => funcionalidade_bug,  #funcionalidade
                         'Serviço' => servico_bug,             #serviço
                         'Adaptativa' => adaptativa_bug,       #adaptativa
                         'Não-Conformidade' => nc_bug,         #não conformidade
                         'Perfectiva' => perfectiva_bug,       #perfectiva
                         'Preventiva' => preventiva_bug,       #preventiva
                         'Estudo' => estudo_bug,               #estudo
                         'Status Report' => statusreport_bug,  #status report
                         'Processo' => processo_bug            #processo
                         }

      # Modified Role
      #roles = Role.find(:all, :conditions => {:builtin => 0}, :order => 'position ASC')
      #manager_role = roles[0]
      #developer_role = roles[1]
      #DEFAULT_ROLE = roles.last
      #ROLE_MAPPING = {10 => DEFAULT_ROLE, # viewer
      #                25 => DEFAULT_ROLE, # reporter
      #                40 => DEFAULT_ROLE, # updater
      #                55 => developer_role, # developer
      #                70 => manager_role, # manager
      #                90 => manager_role # administrator
      #                }

      reporter_role = Role.find_by_position(6)
      developer_role = Role.find_by_position(5)
      analista_role = Role.find_by_position(4)
      manager_role = Role.find_by_position(3)
      administrator_role = Role.find_by_position(7)
      DEFAULT_ROLE = Role.find_by_position(1)
      ROLE_MAPPING = {10 => DEFAULT_ROLE,   	  # viewer
                      25 => reporter_role,   	  # reporter
                      40 => DEFAULT_ROLE,   	  # updater
                      55 => developer_role, 	  # developer
                      60 => analista_role, 	  # analista
                      70 => manager_role,   	  # manager
                      90 => administrator_role    # administrator
                      }

      CUSTOM_FIELD_TYPE_MAPPING = {0 => 'string', # String
                                   1 => 'int',    # Numeric
                                   2 => 'int',    # Float
                                   3 => 'list',   # Enumeration
                                   4 => 'string', # Email
                                   5 => 'bool',   # Checkbox
                                   6 => 'list',   # List
                                   7 => 'list',   # Multiselection list
                                   8 => 'date',   # Date
                                   }

      RELATION_TYPE_MAPPING = {1 => IssueRelation::TYPE_RELATES,    # related to
                               2 => IssueRelation::TYPE_RELATES,    # parent of
                               3 => IssueRelation::TYPE_RELATES,    # child of
                               0 => IssueRelation::TYPE_DUPLICATES, # duplicate of
                               4 => IssueRelation::TYPE_DUPLICATES  # has duplicate
                               }

		FIELD_NAME_MAPPING = {"Data Início Prevista" => 'attr', 		#attributes
					"Data Término Prevista" => 'attr',		#attributes
					"project_id" => 'attr',			#attributes
					"status" => 'attr',				#attributes
					"category" => 'attr',				#attributes
					"handler_id" => 'attr',			#attributes
					"severity" => 'attr',				#attributes
					"fixed_in_version" => 'attr'			#attributes
					}

		ATTRIBUTES_MAPPING = {"Data Início Prevista" => "due_date", 	#due date
					"Data Término Prevista" => "start_date",	#start date
					"project_id" => "project_id",		#project
					"status" => "status_id",			#status
					"category" => "tracker_id",			#tracker
					"handler_id" => "assingned_id",		#assingned
					"severity" => "priority_id",			#priority
					"fixed_in_version" => "fixed_version_id"	#fixed version
					}
    class MantisUser < ActiveRecord::Base
      self.table_name = :m_user_t

      def firstname
        @firstname = realname.blank? ? username : realname.split.first[0..29]
        @firstname
      end

      def lastname
        @lastname = realname.blank? ? '-' : realname.split[1..-1].join(' ')[0..29]
        @lastname = '-' if @lastname.blank?
        @lastname
      end

      def email
        if read_attribute(:email).match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i) &&
             !User.find_by_mail(read_attribute(:email))
          @email = read_attribute(:email)
        else
          @email = "#{username}@foo.bar"
        end
      end

      # Modified added .tr('_', '.')
      def username
        read_attribute(:username)[0..29].gsub(/[^a-zA-Z0-9_\-@\.]/, '-').tr('_', '.')
      end
    end

    class MantisProject < ActiveRecord::Base
      self.table_name = :m_project_t
      has_many :versions, :class_name => "MantisVersion", :foreign_key => :project_id
      #has_many :categories, :class_name => "MantisCategory", :foreign_key => :project_id
      has_many :news, :class_name => "MantisNews", :foreign_key => :project_id
      has_many :members, :class_name => "MantisProjectUser", :foreign_key => :project_id

      # Modified read_attribute(:name).gsub(/[^a-z0-9\-]+/, '-').slice(0, Project::IDENTIFIER_MAX_LENGTH)
      def identifier
        read_attribute(:name).downcase.gsub(/[^a-z0-9\-]+/, '')
      end
    end

    class MantisProjectHierarchy < ActiveRecord::Base
      set_table_name :m_project_hierarchy_t
    end

    class MantisVersion < ActiveRecord::Base
      self.table_name = :m_project_version_t

      def version
        read_attribute(:version)[0..29]
      end

      def description
        read_attribute(:description)[0..254]
      end
    end

    class MantisCategory < ActiveRecord::Base
      set_table_name :m_category_t
      #has_many :bugs, class_name => "MantisCategory", :foreign_key => :category_id

      def name
        read_attribute(:name).slice(0,30)
      end
    end

    class MantisProjectUser < ActiveRecord::Base
      self.table_name = :m_project_user_list_t
    end

    class MantisBug < ActiveRecord::Base
      self.table_name = :m_bug_t
      belongs_to :bug_text, :class_name => "MantisBugText", :foreign_key => :bug_text_id
      belongs_to :category, :class_name => "MantisCategory", :foreign_key => :category_id
      has_many :bug_notes, :class_name => "MantisBugNote", :foreign_key => :bug_id
      has_many :bug_files, :class_name => "MantisBugFile", :foreign_key => :bug_id
      has_many :bug_monitors, :class_name => "MantisBugMonitor", :foreign_key => :bug_id
      has_many :bug_history, :class_name => "MantisBugHistory", :foreign_key => :bug_id
    end

    class MantisBugText < ActiveRecord::Base
      self.table_name = :m_bug_text_t

      # Adds Mantis steps_to_reproduce and additional_information fields
      # to description if any
      def full_description
        full_description = description
        full_description += "\n\n*Steps to reproduce:*\n\n#{steps_to_reproduce}" unless steps_to_reproduce.blank?
        full_description += "\n\n*Additional information:*\n\n#{additional_information}" unless additional_information.blank?
        full_description
      end
    end

    class MantisBugNote < ActiveRecord::Base
      self.table_name = :m_bugnote_t
      belongs_to :bug, :class_name => "MantisBug", :foreign_key => :bug_id
      belongs_to :bug_note_text, :class_name => "MantisBugNoteText", :foreign_key => :bugnote_text_id
    end

    class MantisBugNoteText < ActiveRecord::Base
      self.table_name = :m_bugnote_text_t
    end

    class MantisBugHistory < ActiveRecord::Base
      set_table_name :m_bug_history_t
      set_inheritance_column :none
      belongs_to :bug, :class_name => "MantisBug", :foreign_key => :bug_id

      attr_accessible :name, :old_value, :new_value
    end


    class MantisBugFile < ActiveRecord::Base
      self.table_name = :m_bug_file_t

      def size
        filesize
      end

      def original_filename
        MantisMigrate.encode(filename)
      end

      def content_type
        file_type
      end

      def read(*args)
          if @read_finished
              nil
          else
              @read_finished = true
              content
          end
      end
    end

    class MantisBugRelationship < ActiveRecord::Base
      self.table_name = :m_bug_relationship_t
    end

    class MantisBugMonitor < ActiveRecord::Base
      self.table_name = :m_bug_monitor_t
    end

    class MantisNews < ActiveRecord::Base
      self.table_name = :m_news_t
    end

    class MantisCustomField < ActiveRecord::Base
      self.table_name = :m_custom_field_t
      set_inheritance_column :none
      has_many :values, :class_name => "MantisCustomFieldString", :foreign_key => :field_id
      has_many :projects, :class_name => "MantisCustomFieldProject", :foreign_key => :field_id

      def format
        read_attribute :type
      end

      def name
        read_attribute(:name)[0..29]
      end
    end

    class MantisCustomFieldProject < ActiveRecord::Base
      self.table_name = :m_custom_field_project_t
    end

    class MantisCustomFieldString < ActiveRecord::Base
      self.table_name = :m_custom_field_string_t
    end

    def self.mantis_date_convert(time_stamp)
      DateTime.strptime(time_stamp.to_s, "%s") unless time_stamp.to_s.empty?
    end


    def self.migrate

      # Users
      print "Migrating users"
      User.delete_all "login <> 'admin'"
      users_map = {}
      users_migrated = 0
      MantisUser.find(:all).each do |user|
        u = User.new :firstname => encode(user.firstname),
                     :lastname => encode(user.lastname),
                     :mail => user.email,
                     :last_login_on => user.last_visit
        u.login = user.username
        u.password = 'redmine12345'
        u.language = 'pt-BR'
        u.status = User::STATUS_LOCKED if user.enabled != 1
        u.admin = true if user.access_level == 90
        next unless u.save!
        users_migrated += 1
        users_map[user.id] = u.id
        print '.'
        STDOUT.flush
      end
      puts


      # Projects
      print "Migrating projects"
      Project.destroy_all
      projects_map = {}
      versions_map = {}
      #categories_map = {}

      MantisProject.find(:all).each do |project|
        p = Project.new :name => encode(project.name),
                        :description => encode(project.description)
        p.identifier = project.identifier
	p.is_public = 0
        next unless p.save
        projects_map[project.id] = p.id
        p.enabled_module_names = ['issue_tracking', 'news', 'wiki']
        #p.trackers << TRACKER_BUG unless p.trackers.include?(TRACKER_BUG)
        #p.trackers << TRACKER_FEATURE unless p.trackers.include?(TRACKER_FEATURE)
        p.save
        print '.'
        STDOUT.flush

        # Project members
        project.members.each do |member|
          m = Member.new :user => User.find_by_id(users_map[member.user_id]),
                         :roles => [ROLE_MAPPING[member.access_level] || DEFAULT_ROLE]
          m.project = p
          m.save
        end

        # Project versions
        project.versions.each do |version|
          v = Version.new :name => encode(version.version),
                          :description => encode(version.description),
                          :effective_date => mantis_date_convert(version.date_order).to_date
          v.project = p
          v.save
          versions_map[version.id] = v.id
        end

        # Project categories
        #project.categories.each do |category|
        # g = Tracker.new :name => TRACKER_MAPPING[category.name] || DEFAULT_TRACKER
        #  g = IssueCategory.new :name => category.name[0,30]
        #  g.project = p
        #  g.save
        #  categories_map[category.category] = g.id
	#  p categories_map
	#  puts "\n"
        #end
      end
      puts

      # Project Hierarchy
      print "Making Project Hierarchy"
      MantisProjectHierarchy.find(:all).each do |link|
        next unless p = Project.find_by_id(projects_map[link.child_id])
        p.set_parent!(projects_map[link.parent_id])
        print '.'
      end
      puts

      # Bugs
      print "Migrating bugs"
      Issue.destroy_all
      issues_map = {}
      journals_map = {}
      #keep_bug_ids = (Issue.count == 1)

      MantisBug.find_each(:batch_size => 200) do |bug|
		begin
        next unless projects_map[bug.project_id] && users_map[bug.reporter_id]
        i = Issue.new :project_id => projects_map[bug.project_id],
                      :subject => encode(bug.summary),
                      :description => encode(bug.bug_text.full_description),
                      :priority => PRIORITY_MAPPING[bug.priority] || DEFAULT_PRIORITY,
                      :created_on => mantis_date_convert(bug.date_submitted),
                      :updated_on => mantis_date_convert(bug.last_updated),
                      :start_date => mantis_date_convert(bug.date_submitted)
                      #:tracker_id => TRACKER_MAPPING[bug.category.name] || DEFAULT_TRACKER
        i.author = User.find_by_id(users_map[bug.reporter_id])
        i.fixed_version = Version.find_by_project_id_and_name(i.project_id, bug.fixed_in_version) unless bug.fixed_in_version.blank?
        i.status = STATUS_MAPPING[bug.status] || DEFAULT_STATUS
        i.done_ratio = (i.status_id == 5 ? 100 : 0)
        i.tracker = TRACKER_MAPPING[bug.category.name] || DEFAULT_TRACKER
        #i.tracker = (bug.severity == 10 ? TRACKER_FEATURE : TRACKER_BUG)
	i.is_private = (i.tracker == 5 ? 1 : 0)
        i.id = bug.id # if keep_bug_ids
        next unless i.save
        issues_map[bug.id] = i.id
        print '.'
        STDOUT.flush

        # Assignee
        # Redmine checks that the assignee is a project member
        if (bug.handler_id && users_map[bug.handler_id])
          i.assigned_to = User.find_by_id(users_map[bug.handler_id])
          i.save(:validate => false)
        end

        # Bug notes
        #bug.bug_notes.each do |note|
          #begin
            #next unless users_map[note.reporter_id]
            #n = Journal.new :notes => encode(note.bug_note_text.note),
              #:created_on => mantis_date_convert(note.date_submitted)
            #n.user = User.find_by_id(users_map[note.reporter_id])
            #n.journalized = i
            #n.private_notes = (note.view_state == 50 ? 1 : 0)
            #n.save
          #rescue
            #print 'note error'
            #print note.id
          #end
        #end

        #Bug history
        bug.bug_history.each do |history|
          begin
            next unless users_map[history.user_id]
            n = Journal.new :created_on => mantis_date_convert(history.date_modified)
            n.user = User.find_by_id(users_map[history.user_id])
            n.journalized = i

            if history.type == 0 and FIELD_NAME_MAPPING[history.field_name] and ATTRIBUTES_MAPPING[history.field_name]
              n.notes = ""
              n.save!
              jd = JournalDetail.new :journal_id => n.id,
                                     :property => ATTRIBUTES_MAPPING[history.field_name],
                                     :prop_key => FIELD_NAME_MAPPING[history.field_name],
                                     :old_value => ((history.field_name == "Data Início Prevista" or history.field_name == "Data Término Prevista") ? mantis_date_convert(history.old_value) : history.old_value),
                                     :value => ((history.field_name == "Data Início Prevista" or history.field_name == "Data Término Prevista") ? mantis_date_convert(history.new_value) : history.new_value)
              jd.save
            elsif history.type == 2
              bug_note = MantisBugNote.find_by_id(history.old_value)
              if bug_note
                n.notes = encode(bug_note.bug_note_text.note)
                n.private_notes = (bug_note.view_state == 50 ? 1 : 0)
                n.save!
              end
            end
          rescue Exception => e
            debugger
            print "history error"
            print history.id
          end
        end

        # Bug files
        bug.bug_files.each do |file|
          begin
          a = Attachment.new :created_on => mantis_date_convert(file.date_added)
          a.file = file
          a.author = User.find :first
          a.container = i
          a.save
          rescue
        print 'file error'
        print file.id
        end
        end

        # Bug monitors
        bug.bug_monitors.each do |monitor|
          next unless users_map[monitor.user_id]
          i.add_watcher(User.find_by_id(users_map[monitor.user_id]))
        end
        rescue
        print "bug error"
        print  bug.id
        print "\n"
        end
      end

      # update issue id sequence if needed (postgresql)
      Issue.connection.reset_pk_sequence!(Issue.table_name) if Issue.connection.respond_to?('reset_pk_sequence!')
      puts

      # Bug relationships
      print "Migrating bug relations"
      MantisBugRelationship.find(:all).each do |relation|
        next unless issues_map[relation.source_bug_id] && issues_map[relation.destination_bug_id]
        r = IssueRelation.new :relation_type => RELATION_TYPE_MAPPING[relation.relationship_type]
        r.issue_from = Issue.find_by_id(issues_map[relation.source_bug_id])
        r.issue_to = Issue.find_by_id(issues_map[relation.destination_bug_id])
        pp r unless r.save
        print '.'
        STDOUT.flush
      end
      puts

      # News
      print "Migrating news"
      News.destroy_all
      MantisNews.find(:all, :conditions => 'project_id > 0').each do |news|
        next unless projects_map[news.project_id]
        n = News.new :project_id => projects_map[news.project_id],
                     :title => encode(news.headline[0..59]),
                     :description => encode(news.body),
                     :created_on => mantis_date_convert(news.date_posted)
        n.author = User.find_by_id(users_map[news.poster_id])
        n.save
        print '.'
        STDOUT.flush
      end
      puts

      # Custom fields
      print "Migrating custom fields"
      IssueCustomField.destroy_all
      MantisCustomField.find(:all).each do |field|
        f = IssueCustomField.new :name => field.name[0..29],
                                 :field_format => CUSTOM_FIELD_TYPE_MAPPING[field.format],
                                 :min_length => field.length_min,
                                 :max_length => field.length_max,
                                 :regexp => field.valid_regexp,
                                 :possible_values => field.possible_values.split('|'),
                                 :is_required => field.require_report?
        next unless f.save
        print '.'
        STDOUT.flush

        # Trackers association
        f.trackers = Tracker.find :all

        # Projects association
        field.projects.each do |project|
          f.projects << Project.find_by_id(projects_map[project.project_id]) if projects_map[project.project_id]
        end

        # Values
        field.values.each do |value|
          v = CustomValue.new :custom_field_id => f.id,
                              :value => value.value

	  if IssueCustomField.find(f.id).field_format == CUSTOM_FIELD_TYPE_MAPPING[8]
	    v.value =  mantis_date_convert(v.value) unless v.value.empty?
	  end

          v.customized = Issue.find_by_id(issues_map[value.bug_id]) if issues_map[value.bug_id]
          v.save
        end unless f.new_record?
      end
      puts

      puts
      puts "Users:           #{users_migrated}/#{MantisUser.count}"
      puts "Projects:        #{Project.count}/#{MantisProject.count}"
      puts "Memberships:     #{Member.count}/#{MantisProjectUser.count}"
      puts "Versions:        #{Version.count}/#{MantisVersion.count}"
      puts "Categories:      #{IssueCategory.count}/#{MantisCategory.count}"
      puts "Bugs:            #{Issue.count}/#{MantisBug.count}"
      puts "Bug notes:       #{Journal.count}/#{MantisBugNote.count}"
      puts "Bug files:       #{Attachment.count}/#{MantisBugFile.count}"
      puts "Bug relations:   #{IssueRelation.count}/#{MantisBugRelationship.count}"
      puts "Bug monitors:    #{Watcher.count}/#{MantisBugMonitor.count}"
      puts "News:            #{News.count}/#{MantisNews.count}"
      puts "Custom fields:   #{IssueCustomField.count}/#{MantisCustomField.count}"
    end

    def self.encoding(charset)
      @ic = Iconv.new('UTF-8', charset)
    rescue Iconv::InvalidEncoding
      return false
    end

    def self.establish_connection(params)
      constants.each do |const|
        klass = const_get(const)
        next unless klass.respond_to? 'establish_connection'
        klass.establish_connection params
      end
    end

    def self.encode(text)
      @ic.iconv text
    rescue
      text
    end
  end

  puts
  if Redmine::DefaultData::Loader.no_data?
    puts "Redmine configuration need to be loaded before importing data."
    puts "Please, run this first:"
    puts
    puts "  rake redmine:load_default_data RAILS_ENV=\"#{ENV['RAILS_ENV']}\""
    exit
  end

  puts "WARNING: Your Redmine data will be deleted during this process."
  print "Are you sure you want to continue ? [y/N] "
  STDOUT.flush
  break unless STDIN.gets.match(/^y$/i)

  # Default Mantis database settings
  db_params = {:adapter => 'mysql2',
               :database => 'mantis',
               :host => 'localhost',
               :username => 'root',
               :password => '' }

  puts
  puts "Please enter settings for your Mantis database"
  [:adapter, :host, :database, :username, :password].each do |param|
    print "#{param} [#{db_params[param]}]: "
    value = STDIN.gets.chomp!
    db_params[param] = value unless value.blank?
  end

  while true
    print "encoding [UTF-8]: "
    STDOUT.flush
    encoding = STDIN.gets.chomp!
    encoding = 'UTF-8' if encoding.blank?
    break if MantisMigrate.encoding encoding
    puts "Invalid encoding!"
  end
  puts

  # Make sure bugs can refer bugs in other projects
  Setting.cross_project_issue_relations = 1 if Setting.respond_to? 'cross_project_issue_relations'

  # Turn off email notifications
  Setting.notified_events = []

  MantisMigrate.establish_connection db_params
  MantisMigrate.migrate
end
end
